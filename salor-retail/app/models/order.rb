# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class Order < ActiveRecord::Base

  include SalorScope
  include SalorBase

  has_many :order_items
  has_many :payment_method_items
  has_many :paylife_structs
  has_many :histories, :as => :model
  has_many :drawer_transactions
  has_one :receipt
  belongs_to :user
  belongs_to :company
  belongs_to :customer
  belongs_to :vendor
  belongs_to :cash_register
  belongs_to :drawer
  belongs_to :tax_profile
  belongs_to :origin_country, :class_name => 'Country', :foreign_key => 'origin_country_id'
  belongs_to :destination_country, :class_name => 'Country', :foreign_key => 'destination_country_id'
  belongs_to :sale_type
  has_one :proforma_order, :class_name => Order, :foreign_key => :proforma_order_id


  monetize :total_cents, :allow_nil => true
  monetize :tax_amount_cents, :allow_nil => true
  monetize :cash_cents, :allow_nil => true
  monetize :lc_amount_cents, :allow_nil => true
  monetize :change_cents, :allow_nil => true
  monetize :payment_total_cents, :allow_nil => true
  monetize :noncash_cents, :allow_nil => true
  monetize :rebate_amount_cents, :allow_nil => true
  
  validates_presence_of :user_id
  validates_presence_of :drawer_id
  validates_presence_of :company_id
  validates_presence_of :vendor_id
  validates_presence_of :user_id
  validates_presence_of :cash_register_id

  
  #scope :last_seven_days, lambda { where(:created_at => 7.days.ago.utc...Time.now.utc) }
  scope :unpaid, lambda { 
    t = self.table_name
    where(" ( `#{t}`.paid IS NULL AND ( `#{t}`.total_cents > 0 AND `#{t}`.total IS NOT NULL )  OR  ( `#{t}`.paid = 1 AND `#{t}`.unpaid_invoice IS TRUE) )").where(:is_quote => nil) 
  }
  
  scope :normal_orders, lambda {
      where(:is_quote => nil, :is_proforma => nil)
  }
  
  scope :normal_completed, lambda {
      normal_orders.where(:paid => true)
  }
  
  scope :quotes, lambda {
    where(:is_quote => true, :paid => true)
  }
  
  # These two associations are here for eager loading to speed things up
  has_many :coupons, :class_name => "OrderItem", :conditions => "behavior = 'coupon' and hidden != 1" 
  
  has_many :gift_cards, :class_name => "OrderItem", :conditions => "behavior = 'gift_card' and hidden != 1"
  
  def as_csv
    return attributes
  end
  
  def amount_paid
    Money.new(self.payment_method_items.visible.sum(:amount_cents), self.currency)
  end
  
  def nonrefunded_item_count
    self.order_items.visible.where(:refunded => nil).count
  end

  def loyalty_card
    if self.customer
      return self.customer.loyalty_cards.visible.first
    end
  end
  
  def toggle_buy_order=(x)
    self.buy_order = !self.buy_order
    self.order_items.visible.each do |oi|
      oi.toggle_buyback=(x)
    end
    self.calculate_totals
  end

  def toggle_is_proforma=(x)
    self.is_proforma = !self.is_proforma
    if self.is_proforma
      zero_tax_profile = self.vendor.tax_profiles.visible.find_by_value(0)
      if zero_tax_profile.nil?
        raise "A proforma invoice needs a TaxProfile with value 0. You have to create one before you can proceed."
      end
      self.order_items.visible.each do |oi|
        oi.tax_profile = zero_tax_profile
        oi.tax = zero_tax_profile.value
        oi.calculate_totals
      end
      self.tax_profile = zero_tax_profile
      self.calculate_totals
      
    else
      # reset all order items to Item default
      self.order_items.each do |oi|
        oi.tax_profile = oi.item.tax_profile
        oi.tax = oi.item.tax_profile.value
        oi.calculate_totals
      end
      self.tax_profile = nil
      self.calculate_totals
    end
  end
  
  def tax_profile_id=(id)
    if id.blank?
      # reset all order items to Item default
      self.order_items.each do |oi|
        oi.tax_profile = oi.item.tax_profile
        oi.tax = oi.item.tax_profile.value
        oi.calculate_totals
      end
      write_attribute :tax_profile_id, nil
    else
      tax_profile = self.vendor.tax_profiles.visible.find_by_id(id)
      self.order_items.each do |oi|
        oi.tax_profile = tax_profile
        oi.tax = tax_profile.value
        oi.calculate_totals
      end
    end
    self.calculate_totals
  end
  
  def rebate=(r)
    self.order_items.visible.each do |oi|
      oi.rebate = r
      oi.save # since we are not in the OrderItem model, we have to call save, otherwise oi.calculate_totals will not see the unsaved rebate. this is just how Ruby (or Rails) behaves.
      oi.calculate_totals
    end
    self.calculate_totals
  end
  
  def net
    return self.total - self.tax_amount
  end
  
#   def skus=(list)
#     list.each do |s|
#       if s.class == Array then
#         qty = s[1]
#         s = s[0]
#       end
#       item = Item.get_by_code(s)
#       if item then
#         if item.class == LoyaltyCard then
#           self.customer = item
#         else
#           oi = self.add_item(item)
#           if qty then
#             oi.quantity = qty
#           end
#         end
#       end #if item
#     end # end list.each
#   end


  def add_order_item(params={})
    return nil if params[:sku].blank?
    if self.completed_at then
      log_action "Order is completed already, cannot add items to it #{self.completed_at}"
    end
    
    # get existing regular item
    oi = self.order_items.visible.where(:no_inc => nil, :sku => params[:sku]).first
    if oi then
      if oi.is_normal?
        log_action "Item is normal, and present, just increment"
        oi.quantity += 1 
        oi.modify_price_for_actions       
        oi.calculate_totals
        oi.save
        self.calculate_totals
        return oi
      else
        log_action "Item is not normal but is #{oi.behavior}. Will not increment."
      end
    else
      log_action "OrderItem not found on order, or existing OrderItem is set to no_inc. Will not increment."
    end
    
    # at this point, we know that the added order item is not yet in the order. so we add a new one
    i = self.get_item_by_sku(params[:sku])
    log_action "Item is: #{i.inspect}"
    if i.class == LoyaltyCard then
      log_action "Item is a loyalty card"
      self.customer = i.customer
      self.tag = self.customer.full_name
      self.save
      return nil
    end
    
    # This Item with code G000000000000 is special and has to be created manually
    if i.class == Item and i.item_type.behavior == 'gift_card' and i.sku == "G000000000000"
      log_action "Dynamic Giftcard SKU detected"
      new_i = create_dynamic_gift_card_item
      i = new_i
    end
    
    # finally create the order item
    oi = OrderItem.new
    oi.order = self
    oi.drawer = self.drawer
    oi.user = self.user
    oi.set_attrs_from_item(i)
    if params[:sku].include?('.') or params[:sku].include?(',')
      log_action "Setting no_inc since it is a price-only item."
      oi.no_inc = true
    end
    oi.no_inc ||= params[:no_inc]
    log_action "no_inc is: #{oi.no_inc.inspect}"
    oi.modify_price
    oi.calculate_totals
    self.order_items << oi
    self.calculate_totals
    return oi
  end

  
  
  def create_dynamic_gift_card_item
    auto_giftcard_item = self.vendor.items.visible.find_by_sku("G000000000000")
    zero_tax_profile = self.vendor.tax_profiles.visible.where(:value => 0).first

    if zero_tax_profile.nil?
      log_action "No Zero TaxProfile has been found"
      raise "NoZeroTaxProfileFound" 
    end
    timecode = Time.now.strftime('%y%m%d%H%M%S')
    i = Item.new
    i.sku = "G#{timecode}"
    i.vendor = self.vendor
    i.company = self.company
    i.currency = self.vendor.currency
    i.tax_profile = zero_tax_profile
    i.category = auto_giftcard_item.category
    i.name = "Auto Giftcard #{timecode}"
    i.must_change_price = true
    i.item_type = self.vendor.item_types.visible.find_by_behavior('gift_card')
    if not i.save then
      raise "order.create_dynamic_gift_card_item: #{ i.errors.messages }"
    end
    return i
  end
  
  # called by complete
  def update_giftcard_remaining_amounts
    gcs = self.order_items.visible.where(:behavior => 'gift_card', :activated => true)
    gcs.each do |gc|
      i = gc.item
      i.gift_card_amount += gc.price # gc.price is always negative, so this is actually a subtraction
      i.save
    end
  end
  
  # called by complete
  def activate_giftcard_items
    gcs = self.order_items.visible.where(:behavior => 'gift_card', :activated => nil)
    gcs.each do |gc|
      item = gc.item
      item.activated = true
      item.gift_card_amount = item.price
      item.save
    end
  end
  

  
  
  
  def get_item_by_sku(sku)    
    item = self.vendor.items.visible.find_by_sku(sku)
    return item if item # a sku was entered

    m = self.vendor.gs1_regexp.match(sku)
    item = self.vendor.items.visible.where(:is_gs1 => true).find_by_sku(m[1]) if m
    return item if item # a GS1 barcode was entered

    lcard = self.company.loyalty_cards.visible.find_by_sku(sku)
    return lcard if lcard # a loyalty card was entered
    
    # if nothing existing has been found, create a new item
    i = Item.new
    i.item_type = self.vendor.item_types.find_by_behavior('normal')
    i.behavior = i.item_type.behavior
    i.tax_profile = self.vendor.tax_profiles.where(:default => true).first
    i.vendor = self.vendor
    i.company = self.company
    i.currency = self.vendor.currency
    i.name = sku
    pm = sku.match(/(\d{1,9}[\.\,]\d{1,2})/)
    if pm and pm[1]
      # a price in the format xx,xx was entered
      i.sku = "DMY" + Time.now.strftime("%y%m%d") + rand(999).to_s
      i.price = sku
    else
      # dummy item
      # we didn't find the item, let's see if a plugin wants to handle it
      i.sku = sku
      i.price = 0
      i = Action.run(i.vendor, i, :on_sku_not_found) 
    end
    i.save
    return i
  end

  def make_from_proforma_order
    final = self.dup
    final.completed_at = nil
    final.is_proforma = nil
    final.paid = nil
    final.paid_at = nil
    final.created_at = DateTime.now
    final.tax_profile = nil
    final.tax = nil
    final.proforma_order = self
    final.save
    
    self.order_items.visible.each do |oi|
      noi = oi.dup
      noi.order = final
      # reset the tax profile, since all OrderItems of a proforma invoice have zero taxes. the final invoice however needs the actual taxes.
      noi.tax_profile = noi.item.tax_profile
      noi.tax = noi.item.tax_profile.value
      result = noi.save
      raise "Could not save OrderItem: #{ noi.errors.messages }" if result != true
    end
    
    zero_tax_profile = self.vendor.tax_profiles.visible.find_by_value(0)
    if zero_tax_profile.nil?
      raise "Need a TaxProfile with value of 0"
    end
    
    item = self.get_item_by_sku("DMYACONTO")
    aconto_item_type = self.vendor.item_types.visible.find_by_behavior('aconto')
    item.item_type = aconto_item_type
    item.name = I18n.t("receipts.a_conto")
    item.tax_profile = zero_tax_profile
    item.save


    noi = final.add_order_item({:sku => "DMYACONTO"})
    noi.price = - self.amount_paid
    noi.save # must be called before calulate totals!
    noi.calculate_totals
    
    final.calculate_totals
    
    return final
  end

  

  def calculate_totals
    log_action "Calculating Totals"
    
    _oi_total = self.order_items.visible.sum(:total_cents)
    _oi_tax_amount = self.order_items.visible.sum(:tax_amount_cents)
    
    log_action "Total is: #{_oi_total} and tax is #{_oi_tax_amount}"
   
    self.tax_amount_cents = _oi_tax_amount
    self.total_cents = _oi_total

    if not self.save then
      raise "Order Could Not Be Saved #{ self.errors.messages }"
    end
  end




  

  def complete(params)
    raise "cannot complete a paid order" if self.paid
    
    # History
    h = History.new
    h.url = "Order::complete"
    h.params = $Params
    h.model_id = self.id
    h.model_type = 'Order'
    h.action_taken = "CompleteOrder"
    h.changes_made = "Beginning complete order"
    h.save

    self.paid = true
    self.paid_at = Time.now # TODO: Don't set this for unpaid orders
    self.completed_at = Time.now
    # the user is re-assigned in OrdersController#complete
    self.drawer = self.user.get_drawer
    self.save
    
    self.update_item_quantities
    self.activate_giftcard_items
    self.update_giftcard_remaining_amounts
    self.create_payment_method_items(params)
    self.create_drawer_transaction
    self.update_associations
    self.report_errors_to_technician
    
    
    if self.is_quote
      self.qnr = self.vendor.get_unique_model_number('quote')
    else
      self.nr = self.vendor.get_unique_model_number('order')
    end
    self.save
    
  end
  
  def update_associations
    self.order_items.update_all({
                                 :completed_at => self.completed_at,
                                 :paid_at => self.paid_at,
                                 :paid => self.paid,
                                 :is_proforma => self.is_proforma,
                                 :is_quote => self.is_quote,
                                 :user_id => self.user_id,
                                 :drawer_id => self.drawer_id
                                 })
  end
  
  def create_drawer_transaction
    add_amount = (self.cash - self.change)
    return if add_amount.zero?
    
    drawer = self.user.get_drawer
    
    dt = DrawerTransaction.new
    dt.vendor = self.vendor
    dt.company = self.company
    dt.currency = self.vendor.currency
    dt.user = self.user
    dt.cash_register = self.cash_register
    dt.drawer = drawer
    dt.drawer_amount = drawer.amount
    dt.order = self
    dt.complete_order = true
    dt.amount = add_amount
    dt.save
    
    drawer.amount += add_amount
    drawer.save
  end
  
  def update_item_quantities
    self.order_items.visible.each do |oi|
      items = []
      items << oi.item
      items << oi.item.parts
      items.flatten!
      items.each do |i|
        if not i.ignore_qty and i.behavior == 'normal' and not self.is_proforma
          q = oi.quantity
          q = -q if oi.is_buyback
          Item.transact_quantity(-oi.quantity, i, self)
        end
        i.save
      end
    end
  end
  
  def create_payment_method_items(params)    
    params[:payment_method_items].each do |k,v|
      pm = self.vendor.payment_methods.visible.find_by_id(v[:id])
      
      pmi = PaymentMethodItem.new
      pmi.payment_method = pm
      pmi.vendor = self.vendor
      pmi.company = self.company
      pmi.order = self
      pmi.user = self.user
      pmi.drawer = self.drawer
      pmi.cash_register = self.cash_register
      pmi.paid_at = self.paid_at
      pmi.paid = self.paid
      pmi.completed_at = self.completed_at
      pmi.is_proforma = self.is_proforma
      pmi.is_quote = self.is_quote
      pmi.is_unpaid = self.is_unpaid
      pmi.amount = Money.new(SalorBase.string_to_float(v[:amount]) * 100.0, self.currency)
      pmi.cash = pm.cash
      pmi.quote = pm.quote
      pmi.unpaid = pm.unpaid
      result = pmi.save
      if result != true
        raise "Could not save PaymentMethodItem because #{ pmi.errors.messages }"
      end
      
      self.payment_method_items << pmi
      
      # TODO this should be applied to all PMIs after it was discovered
      self.is_quote = true if pm.quote == true
      self.is_unpaid = true if pm.unpaid == true
    end
    
    self.save
    
    payment_cash = Money.new(self.payment_method_items.visible.where(:cash => true).sum(:amount_cents), self.currency)
    payment_total = Money.new(self.payment_method_items.visible.sum(:amount_cents), self.currency)
    payment_noncash = (payment_total - payment_cash)
    change = (payment_total - self.total)
    change_payment_method = self.vendor.payment_methods.visible.find_by_change(true)

    unless self.is_proforma
      # create a change payment method item
      pmi = PaymentMethodItem.new
      pmi.payment_method = change_payment_method
      pmi.vendor = self.vendor
      pmi.company = self.company
      pmi.order = self
      pmi.user = self.user
      pmi.drawer = self.drawer
      pmi.cash_register = self.cash_register
      pmi.paid_at = self.paid_at
      pmi.paid = self.paid
      pmi.completed_at = self.completed_at
      pmi.is_proforma = self.is_proforma
      pmi.is_quote = self.is_quote
      pmi.is_unpaid = self.is_unpaid
      pmi.amount = change
      pmi.change = true
      result = pmi.save
      if result != true
        raise "Could not save change PaymentMethodItem because #{ pmi.errors.messages }"
      end
      self.payment_method_items << pmi
    else
      change = 0
    end
    
    self.cash = payment_cash
    self.noncash = payment_noncash
    self.change = change
    self.save
  end

  
  
  
  
#   def order_items_as_array
#     items = []
#     self.order_items.visible.each do |oi|
#       items << oi.to_json
#     end
#     return items
#   end

#   def payment_method_sums
#     sums = Hash.new
#     self.payment_methods.each do |pm|
#       s = pm.internal_type.to_sym
#       next if s.nil?
#       sums[s] = 0 if sums[s].nil?
#       pm.amount = 0 if pm.amount.nil?
#       sums[s] += pm.amount
#     end
#     log_action "payment_method_sums #{sums.inspect}"
#     return sums
#   end

#   def payment_display
#     if self.payment_methods.length > 1 then
#       return ["Mix",self.total]
#     else
#       pm = self.payment_methods.first
#       return ['Unk',0] if pm.nil?
#       return [pm.internal_type,self.total]
#     end
#   end
  

  

  def to_list_of_items_raw(array)
    ret = {}
    i = 0
    [:letter,:name,:price,:quantity,:total,:type].each do |k|
      ret[k] = array[i]
      i += 1
    end
    return ret
  end
  
  def to_list_of_taxes_raw(array)
    ret = {}
    i = 0
    [:letter, :value, :net, :tax, :gross].each do |k|
      ret[k] = array[i]
      i += 1
    end
    return ret
  end
  
  
  def report(locale=nil)
    locale ||= I18n.locale
    
    sum_taxes = Hash.new

    self.vendor.tax_profiles.visible.each do |t|
      sum_taxes[t.id] = {
        :total => 0,
        :letter => t.letter,
        :value => 0
      }
    end
    
    total = 0
    list_of_items = ''
    list_of_items_raw = []
    list_of_taxes_raw = []

    integer_format = "%s %-19.19s %6.2f  %3u %8.2f\n"
    float_format = "%s %-19.19s %6.2f  %5.3f %6.2f\n"
    percent_format = "%s %-19.19s %6.1f%% %3u   %6.2f\n"
    tax_format = "   %s: %2i%% %7.2f %7.2f %8.2f\n"

    self.order_items.visible.each do |oi|
      if oi.item
        name = oi.item.get_translated_name(locale)
      else
        # fix for orders where the item was deleted (compatibility with old system)
        name = ''
      end
      taxletter = oi.tax_profile.letter
      

      # --- NORMAL ITEMS ---
      if oi.behavior == 'normal'
        if oi.quantity == Integer(oi.quantity)
          # integer quantity
          list_of_items += integer_format % [
            taxletter,
            name,
            oi.price,
            oi.quantity,
            oi.total
          ]
          list_of_items_raw << to_list_of_items_raw([
                                                     taxletter,
                                                     name,
                                                     oi.price,
                                                     oi.quantity,
                                                     oi.total,
                                                     'integer'
                                                    ])
        else
          # float quantity (e.g. weighed OrderItem)
          list_of_items += float_format % [
            taxletter,
            name,
            oi.price,
            oi.quantity,
            oi.total
          ]
          list_of_items_raw << to_list_of_items_raw([
                                                     taxletter,
                                                     name,
                                                     oi.price,
                                                     oi.quantity,
                                                     oi.total,
                                                     'float'
                                                    ])
        end
      end

      # GIFT CARDS
      if oi.behavior == 'gift_card'
        list_of_items += "%s %-19.19s         %3u   %6.2f\n" % [
          taxletter,
          name,
          oi.quantity,
          oi.total
        ]
        list_of_items_raw << to_list_of_items_raw([
                                                   taxletter,
                                                   name,
                                                   nil,
                                                   oi.quantity,
                                                   oi.total,
                                                   'integer'
                                                  ])
      end

      # COUPONS
      if oi.behavior == 'coupon'
        list_of_items += "  %-19.19s         %3u\n" % [
          oi.item.name,
          oi.quantity
        ]
        list_of_items_raw << to_list_of_items_raw([
                                                   nil,
                                                   oi.item.name,
                                                   nil,
                                                   oi.quantity,
                                                   nil,
                                                   'integer'
                                                  ])
      end

      
      # ACONTO
      if oi.behavior == 'aconto'
        aconto_blurb = "#{ name } (#{ I18n.t('orders.print.invoice') } ##{ self.proforma_order.nr }, #{ I18n.l(self.proforma_order.completed_at, :format => :just_day) })"
        list_of_items += integer_format % [
          taxletter,
          aconto_blurb,
          oi.price,
          oi.quantity,
          oi.total
        ]
        list_of_items_raw << to_list_of_items_raw([
                                                    taxletter,
                                                    aconto_blurb,
                                                    oi.price,
                                                    oi.quantity,
                                                    oi.total,
                                                    'integer'
                                                  ])
      end
      
      # DISCOUNTS
      if oi.discount_amount and not oi.discount_amount.zero? # TODO: get rid of nil values in DB
        discount = oi.discounts.first
        discount_blurb = I18n.t('printr.order_receipt.discount') + ' ' + oi.discount.to_s + ' %'
        list_of_items += "  %-19.19s         %3u\n" % [
          discount_blurb,
          oi.quantity
        ]
        list_of_items_raw << to_list_of_items_raw([
                                                   nil,
                                                   discount_blurb,
                                                   nil,
                                                   oi.quantity,
                                                   nil,
                                                   'integer'
                                                  ])
      end

      # REBATES
      if oi.rebate
        rebate_blurb = I18n.t('printr.order_receipt.rebate') + " " + oi.rebate.to_s + " %"
        list_of_items += "  %-19.19s         %3u\n" % [
          rebate_blurb,
          oi.quantity
        ]
        list_of_items_raw << to_list_of_items_raw([
                                                   nil,
                                                   rebate_blurb,
                                                   nil,
                                                   oi.quantity,
                                                   nil,
                                                   'integer'
                                                  ])
      end
    end


    # --- payment method items ---
    paymentmethods = Hash.new
    self.payment_method_items.visible.where('amount_cents != 0').each do |pmi|
      
      # old databases are somewhat inconsistent, so we need to catch nils
      pmi_amount = pmi.amount.blank? ? Money.new(0, self.vendor.currency) : pmi.amount
      blurb = pmi.payment_method.nil? ? "no pm" : pmi.payment_method.name
      
      blurb = I18n.t('printr.eod_report.refund') + ' ' + blurb if pmi.refund
      paymentmethods[pmi.id] = {
        :name => blurb,
        :amount => pmi_amount
      }
    end

    
    # --- taxes ---
    list_of_taxes = ''
    used_tax_amounts = self.order_items.visible.select("DISTINCT tax")
    used_tax_amounts.each do |r|
      tax_in_percent = r.tax # this is the tax in percent, stored on OrderItem
      tax_profile = self.vendor.tax_profiles.find_by_value(tax_in_percent)
      tax_amount = Money.new(self.order_items.visible.where(:tax => tax_in_percent).sum(:tax_amount_cents), self.currency)
      total = Money.new(self.order_items.visible.where(:tax => tax_in_percent).sum(:total_cents), self.currency)
      next if total.zero?
      list_of_taxes += tax_format % [
        tax_profile.letter,
        tax_in_percent,
        total - tax_amount,
        tax_amount,
        total
      ]
      list_of_taxes_raw << to_list_of_taxes_raw([
                                                 tax_profile.letter,
                                                 tax_profile.value,
                                                 total - tax_amount,
                                                 tax_amount, total
                                                ])
    end
    
    # --- invoice blurbs ---
    invoice_blurb_header = self.vendor.invoice_blurbs.visible.where(:lang => locale, :is_header => true).last
    invoice_blurb_footer = self.vendor.invoice_blurbs.visible.where(:lang => locale).where('is_header IS NOT TRUE').last
    invoice_blurb_header_receipt = invoice_blurb_header.body_receipt if invoice_blurb_header
    invoice_blurb_header_invoice = invoice_blurb_header.body if invoice_blurb_header
    invoice_blurb_footer_receipt = invoice_blurb_footer.body_receipt if invoice_blurb_footer
    invoice_blurb_footer_invoice = invoice_blurb_footer.body if invoice_blurb_footer
    invoice_blurb_header_receipt ||= ''
    invoice_blurb_header_invoice ||= ''
    invoice_blurb_footer_receipt ||= ''
    invoice_blurb_footer_invoice ||= ''
    
    
    
    # --- invoice notes ---
    invoice_note = self.vendor.invoice_notes.visible.where(
      :origin_country_id => self.origin_country_id, 
      :destination_country_id => self.destination_country_id, 
      :sale_type_id => self.sale_type_id
    ).first
    invoice_note_header = invoice_note.note_header if invoice_note
    invoice_note_footer = invoice_note.note_footer if invoice_note
    invoice_note_header ||= ''
    invoice_note_footer ||= ''

    # --- invoice comment ---
    invoice_comment = self.invoice_comment
      
   
    # --- customer data ---
    if self.customer
      customer = {}
      customer[:company_name] = self.customer.company_name
      customer[:first_name] = self.customer.first_name
      customer[:last_name] = self.customer.last_name
      customer[:street1] = self.customer.street1
      customer[:street2] = self.customer.street2
      customer[:postalcode] = self.customer.postalcode
      customer[:tax_number] = self.customer.tax_number
      customer[:city] = self.customer.city
      customer[:country] = self.customer.country
      customer[:state] = self.customer.state
      customer[:current_loyalty_points] = self.loyalty_card.points
    end

    
    # --- output as a hash to be used for outputs ---
    report = Hash.new
    report[:list_of_items] = list_of_items
    report[:list_of_items_raw] = list_of_items_raw
    report[:list_of_taxes] = list_of_taxes
    report[:list_of_taxes_raw] = list_of_taxes_raw
    report[:total] = self.total
    report[:change] = self.change
    report[:paymentmethods] = paymentmethods
    report[:customer] = customer
    report[:unit] = I18n.t('number.currency.format.friendly_unit', :locale => self.vendor.region)
    report[:invoice_blurbs] = {
      :receipt => {
                    :header => invoice_blurb_header_receipt,
                    :footer => invoice_blurb_footer_receipt
                  },
      :invoice => {
                    :header => invoice_blurb_header_invoice,
                    :footer => invoice_blurb_footer_invoice
                  }
    }
    report[:invoice_note] = {
      :header => invoice_note_header,
      :footer => invoice_note_footer
    }
    return report
  end
  
 
  
#   def inspectify
#     txt = "Order[#{self.id}]"
#     [:total,:subtotal,:tax,:gross].each do |f|
#        txt += " #{f}=#{self.send(f)}"
#     end
#     self.order_items.each do |oi|
#       txt += "\n\tOrderItem[#{oi.id}]"
#       [:quantity,:price,:total,:gift_card_amount,:activated].each do |f|
#         txt += " #{f}=#{oi.send(f)}"
#       end
#     end
#     return txt
#   end
  
  
  def escpos_receipt
    report = self.report
    
    friendly_unit = report[:unit]

    vendorname =
    "\e@"     +  # Initialize Printer
    "\e!\x38" +  # doube tall, double wide, bold
    vendor.name + "\n"
    
    receiptblurb_header = ''
    receiptblurb_header +=
    "\e!\x01" +  # Font B
    "\ea\x01" +  # center
    "\n" + report[:invoice_blurbs][:receipt][:header] + "\n"
    
    receiptblurb_footer = ''
    receiptblurb_footer = 
    "\ea\x01" +  # align center
    "\e!\x00" + # font A
    "\n" + report[:invoice_blurbs][:receipt][:footer] + "\n"
    
    header = ''
    header +=
    "\ea\x00" +  # align left
    "\e!\x01" +  # Font B
    I18n.t("receipts.invoice_numer_X_at_time", :number => self.nr, :datetime => I18n.l(self.paid_at, :format => :iso)) + ' ' + self.cash_register.name + "\n"

    header += "\n\n" +
    "\e!\x00" +  # Font A
    "\xc4" * 42 + "\n"

    list_of_items = report[:list_of_items]
    list_of_items += "\xc4" * 42 + "\n"
    
    total = ''
    total_format = "%29.29s %s %8.2f\n"
    total_values = [
      I18n.t('printr.order_receipt.total'),
      report[:unit],
      report[:total]
    ]
    total +=  total_format % total_values
    
    paymentmethods = ''
    report[:paymentmethods].each do |k,v|
      paymentmethods += "%29.29s %s %8.2f\n" % [v[:name], report[:unit], v[:amount]]
    end

    tax_format = "\n\n" +
    "\ea\x01" +  # align center
    "\e!\x01" # Font A
    
    tax_header_format = "         %5.5s     %4.4s  %6.6s\n"
    tax_header_values = [
      I18n.t('printr.order_receipt.net'),
      I18n.t('printr.order_receipt.tax'),
      I18n.t('printr.order_receipt.gross')
    ]
    tax_header = tax_header_format % tax_header_values
    
    list_of_taxes = report[:list_of_taxes]
 
    customer = ''
    if report[:customer]
      customer_format = "%s\n%s %s\n%s\n%s %s\n%s"
      customer_values = [
        report[:customer][:company_name],
        report[:customer][:first_name],
        report[:customer][:last_name],
        report[:customer][:street1],
        report[:customer][:postalcode],
        report[:customer][:city],
        report[:customer][:tax_number]
      ]
      customer += customer_format % customer_values
    end

    duplicate = self.was_printed ? " *** DUPLICATE/COPY/REPRINT *** " : ''

    raw_insertations = {}
    if vendor.receipt_logo_header
      headerlogo = "{::escper}headerlogo{:/}"
      raw_insertations.merge! :headerlogo => vendor.receipt_logo_header
    else
      headerlogo = vendorname
    end
    
    if vendor.receipt_logo_footer
      footerlogo = "{::escper}footerlogo{:/}"
      raw_insertations.merge! :footerlogo => vendor.receipt_logo_footer
    else
      footerlogo = ''
    end

    output_text =
        "\e@" +
        "\ea\x01" +  # align center
        headerlogo +
        receiptblurb_header +
        header +
        list_of_items +
        total +
        paymentmethods +
        tax_format +
        tax_header +
        list_of_taxes +
        customer +
        receiptblurb_footer +
        duplicate +
        "\n" +
        footerlogo +
        "\n\n\n\n\n\n" + # space
        "\x1D\x56\x00" + # cut paper
        "\x1D\x61\x01"   # printer feedback
    
    return { :text => output_text, :raw_insertations => raw_insertations }
  end
  
  def print(cash_register)
    return if self.company.mode != 'local'
    contents = self.escpos_receipt
    
    if nil # is_mac?
      output = Escper::Printer.merge_texts(contents[:text], contents[:raw_insertations])
      File.open("/tmp/" + cash_register.thermal_printer,'wb') { |f|
                                                                f.write output
                                                              }
      `lp -d #{cash_register.thermal_printer} /tmp/#{cash_register.thermal_printer}`

    else
      vp = Escper::VendorPrinter.new({})
      vp.id = 0
      vp.name = cash_register.name
      vp.path = cash_register.thermal_printer
      vp.copies = 1
      vp.codepage = 0
      vp.baudrate = 9600
      
      print_engine = Escper::Printer.new('local', vp)
      print_engine.open
      print_engine.print(0, contents[:text], contents[:raw_insertations])
      print_engine.close
    end
    
    return contents[:text]
  end
    
  def report_errors_to_technician
    if self.vendor.enable_technician_emails == true and not self.vendor.technician_email.blank?
      errors = self.check
      #if errors.any?
        subject = "Errors in Order #{ self.id }"
        body = errors.to_s
        UserMailer.technician_message(self.vendor, subject, body).deliver
        em = Email.new
        em.company = self.company
        em.vendor = self.vendor
        em.receipient = self.vendor.technician_email
        em.subject = subject
        em.body = body
        em.user = self.user
        em.technician = true
        em.model = self
        em.save
      end
    #end
  end
  
  def check
    tests = []
    
    self.order_items.visible.each do |oi|
      result = oi.check
      tests << result unless result == []
    end
    
    # checks for totals
    
    # ---
    should = self.order_items.visible.sum(:total_cents)
    actual = self.total_cents
    pass = should == actual
    msg = "total should be the sum of OrderItem totals"
    type = :orderTotalSum
    tests << {:model=>"Order", :id=>self.id, :t=>type, :m=>msg, :s=>should, :a=>actual} if pass == false
    
    # ---
    should = self.order_items.visible.sum(:tax_amount_cents)
    actual = self.tax_amount_cents
    pass = should == actual
    msg = "tax_amount should be the sum of OrderItem tax_amounts"
    type = :orderTaxSum
    tests << {:model=>"Order", :id=>self.id, :t=>type, :m=>msg, :s=>should, :a=>actual} if pass == false
    
    
    # checks for payment method items
    
    # ---
    unless self.is_proforma == true
      should = self.payment_method_items.sum(:amount_cents)
      actual = self.total_cents
      pass = should == actual
      msg = "PaymentMethodItems sum should match total"
      type = :orderPaymentsTotal
      tests << {:model=>"Order", :id=>self.id, :t=>type, :m=>msg, :s=>should, :a=>actual} if pass == false
    end
    
    # ---
    unless self.is_proforma == true
      should = self.payment_method_items.where(:cash => true).sum(:amount_cents)
      actual = self.drawer_transactions.sum(:amount_cents)
      pass = should == actual
      msg = "Sum of cash PaymentMethodItems should match sum of DrawerTransactions"
      type = :orderCashPaymentsTransactionMatch
      tests << {:model=>"Order", :id=>self.id, :t=>type, :m=>msg, :s=>should, :a=>actual} if pass == false
    end
    
    
    # ---
    unless self.is_proforma == true
      should = self.payment_method_items.where(:change => nil).sum(:amount_cents) - self.total_cents
      actual = self.payment_method_items.where(:change => true).sum(:amount_cents)
      pass = should == actual
      msg = "Change PaymentMethodItem should be correct"
      type = :orderChangePaymentMethodItemCorrect
      tests << {:model=>"Order", :id=>self.id, :t=>type, :m=>msg, :s=>should, :a=>actual} if pass == false
    end
    
    
    # checks for user_id
    
    # ---
    should = [self.user_id]
    actual = self.order_items.visible.collect{ |oi| oi.user_id }.uniq
    pass = should == actual
    msg = "OrderItems should have the same user_id as the Order"
    type = :orderOrderItemsUserMatch
    tests << {:model=>"Order", :id=>self.id, :t=>type, :m=>msg, :s=>should, :a=>actual} if pass == false
    
    # ---
    should = [self.user_id]
    actual = self.payment_method_items.visible.collect{ |pmi| pmi.user_id }.uniq
    pass = should == actual
    msg = "PaymentMethodItems should have the same user_id as the Order"
    type = :orderPaymentMethodItemUserMatch
    tests << {:model=>"Order", :id=>self.id, :t=>type, :m=>msg, :s=>should, :a=>actual} if pass == false
    
    # ---
    if self.drawer_transactions.any?
      should = [self.user_id]
      actual = self.drawer_transactions.visible.collect{ |dt| dt.user_id }.uniq
      pass = should == actual
      msg = "DrawerTransactions should have the same user_id as the Order"
      type = :orderDrawerTransactionUserMatch
      tests << {:model=>"Order", :id=>self.id, :t=>type, :m=>msg, :s=>should, :a=>actual} if pass == false
    end
    
    
    # checks for drawer_id
    
    # ---
    should = [self.drawer_id]
    actual = self.order_items.visible.collect{ |oi| oi.drawer_id }.uniq
    pass = should == actual
    msg = "OrderItems should have the same drawer_id as the Order"
    type = :orderOrderItemsDrawerMatch
    tests << {:model=>"Order", :id=>self.id, :t=>type, :m=>msg, :s=>should, :a=>actual} if pass == false
    
    # ---
    should = [self.drawer_id]
    actual = self.payment_method_items.visible.collect{ |pmi| pmi.drawer_id }.uniq
    pass = should == actual
    msg = "PaymentMethodItems should have the same drawer_id as the Order"
    type = :orderPaymentMethodItemDrawerMatch
    tests << {:model=>"Order", :id=>self.id, :t=>type, :m=>msg, :s=>should, :a=>actual} if pass == false
    
    # ---
    if self.drawer_transactions.any?
      should = [self.drawer_id]
      actual = self.drawer_transactions.visible.collect{ |dt| dt.drawer_id }.uniq
      pass = should == actual
      msg = "DrawerTransactions should have the same drawer_id as the Order"
      type = :orderDrawerTransactionDrawerMatch
      tests << {:model=>"Order", :id=>self.id, :t=>type, :m=>msg, :s=>should, :a=>actual} if pass == false
    end
    
    
    # checks for paid flag
    
    # ---
    should = [self.paid]
    actual = self.order_items.visible.collect{ |oi| oi.paid }.uniq
    pass = should == actual
    msg = "OrderItems should have the same paid flag as the Order"
    type = :orderOrderItemsPaidMatch
    tests << {:model=>"Order", :id=>self.id, :t=>type, :m=>msg, :s=>should, :a=>actual} if pass == false
    
    # ---
    should = [self.paid]
    actual = self.payment_method_items.visible.collect{ |pmi| pmi.paid }.uniq
    pass = should == actual
    msg = "PaymentMethodItems should have the same paid flag as the Order"
    type = :orderPaymentMethodItemsPaidMatch
    tests << {:model=>"Order", :id=>self.id, :t=>type, :m=>msg, :s=>should, :a=>actual} if pass == false
    
    
    # checks for is_proforma flag
    
    # ---
    should = [self.is_proforma]
    actual = self.order_items.visible.collect{ |oi| oi.is_proforma }.uniq
    pass = should == actual
    msg = "OrderItems should have the same is_proforma flag as the Order"
    type = :orderOrderItemsProformaMatch
    tests << {:model=>"Order", :id=>self.id, :t=>type, :m=>msg, :s=>should, :a=>actual} if pass == false
    
    # ---
    should = [self.is_proforma]
    actual = self.payment_method_items.visible.collect{ |pmi| pmi.is_proforma }.uniq
    pass = should == actual
    msg = "PaymentMethodItems should have the same is_proforma flag as the Order"
    type = :orderPaymentMethodItemsProformaMatch
    tests << {:model=>"Order", :id=>self.id, :t=>type, :m=>msg, :s=>should, :a=>actual} if pass == false
    
    
    # checks for is_unpaid flag
    
    # ---
    should = [self.is_unpaid]
    actual = self.order_items.visible.collect{ |oi| oi.is_unpaid }.uniq
    pass = should == actual
    msg = "OrderItems should have the same is_unpaid flag as the Order"
    type = :orderOrderItemsUnpaidMatch
    tests << {:model=>"Order", :id=>self.id, :t=>type, :m=>msg, :s=>should, :a=>actual} if pass == false
    
    # ---
    should = [self.is_unpaid]
    actual = self.payment_method_items.visible.collect{ |pmi| pmi.is_unpaid }.uniq
    pass = should == actual
    msg = "PaymentMethodItems should have the same is_unpaid flag as the Order"
    type = :orderPaymentMethodItemsUnpaidMatch
    tests << {:model=>"Order", :id=>self.id, :t=>type, :m=>msg, :s=>should, :a=>actual} if pass == false
    
    
    # checks for completed_at timestamp
    
    should = [self.completed_at.strftime("%Y%m%d%H%M%S")]
    actual = self.order_items.visible.collect{ |oi| oi.completed_at.strftime("%Y%m%d%H%M%S") }.uniq
    pass = should == actual
    msg = "OrderItems should have the same completed_at timestamp as the Order"
    type = :orderOrderItemsCompletedAtMatch
    tests << {:model=>"Order", :id=>self.id, :t=>type, :m=>msg, :s=>should, :a=>actual} if pass == false
    
    should = [self.completed_at.strftime("%Y%m%d%H%M%S")]
    actual = self.payment_method_items.visible.collect{ |pmi| pmi.completed_at.strftime("%Y%m%d%H%M%S") }.uniq
    pass = should == actual
    msg = "PaymentMethodItems should have the same completed_at timestamp as the Order"
    type = :orderPaymentMethodItemsCompletedAtMatch
    tests << {:model=>"Order", :id=>self.id, :t=>type, :m=>msg, :s=>should, :a=>actual} if pass == false
    
    
    # checks for paid_at timestamp
    
    should = [self.paid_at.strftime("%Y%m%d%H%M%S")]
    actual = self.order_items.visible.collect{ |oi| oi.paid_at.strftime("%Y%m%d%H%M%S") }.uniq
    pass = should == actual
    msg = "OrderItems should have the same paid_at timestamp as the Order"
    type = :orderOrderItemsPaidAtMatch
    tests << {:model=>"Order", :id=>self.id, :t=>type, :m=>msg, :s=>should, :a=>actual} if pass == false
    
    should = [self.paid_at.strftime("%Y%m%d%H%M%S")]
    actual = self.payment_method_items.visible.collect{ |pmi| pmi.paid_at.strftime("%Y%m%d%H%M%S") }.uniq
    pass = should == actual
    msg = "PaymentMethodItems should have the same paid_at timestamp as the Order"
    type = :orderPaymentMethodItemsPaidAtMatch
    tests << {:model=>"Order", :id=>self.id, :t=>type, :m=>msg, :s=>should, :a=>actual} if pass == false
    
    
    # checks for is_quote flag
    
    # ---
    should = [self.is_quote]
    actual = self.order_items.visible.collect{ |oi| oi.is_quote }.uniq
    pass = should == actual
    msg = "OrderItems should have the same is_quote flag as the Order"
    type = :orderOrderItemsQuoteMatch
    tests << {:model=>"Order", :id=>self.id, :t=>type, :m=>msg, :s=>should, :a=>actual} if pass == false
    
    
    # checks for user_id and drawer_id match
    should = self.user.get_drawer.id
    actual = self.drawer_id
    pass = should == actual
    msg = "Order specifies drawer_id #{ actual } and user_id #{ self.user_id } but this user's drawer is #{ should }."
    type = :orderUserDrawerMatch
    tests << {:model=>"Order", :id=>self.id, :t=>type, :m=>msg, :s=>should, :a=>actual} if pass == false
    
    
    return tests
  end
  
  # for better debugging in the console
  def self.last2
    id = Order.last.id
    return Order.find_by_id id-1   
  end
  
  def to_json
    self.total = 0 if self.total.nil?
    attrs = {
      :total => self.total.to_f,
      :rebate => self.rebate.to_f,
      :lc_points => self.lc_points,
      :id => self.id,
      :buy_order => self.buy_order,
      :tag => self.tag,
      :sale_type_id => self.sale_type_id,
      :destination_country_id => self.destination_country_id,
      :origin_country_id => self.origin_country_id,
      :sale_type  => self.sale_type,
      :origin => self.origin_country,
      :destination => self.destination_country,
      :is_proforma => self.is_proforma,
      :order_items_length => self.order_items.visible.size
    }
    if self.customer then
      attrs[:customer] = self.customer.json_attrs
      attrs[:loyalty_card] = self.customer.loyalty_cards.visible.last.json_attrs if self.customer.loyalty_cards.visible.last
    end
    attrs.to_json
  end
  
  def self.order_items_to_json(order_items=[])
    "[#{order_items.collect { |oi| oi.to_json }.join(", ") }]"
  end
end
