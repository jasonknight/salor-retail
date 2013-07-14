# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

# THE PRICE REDUCTION SYSTEM
# ==========================
#
#
# Gift Cards
# ----------
# A gift card is a self-issued currency which you can sell and buy to and from your customers. 

# It has to be sold with a tax of 0% since it is not known in advance which goods will be bought by it when the customer returns. In many countries, there are different tax percentages for different kinds of items. When a customer pays with a gift card, it is added to the Order as an OrderItem. Its price becomes the negative order total at the point of time it is scanned, but not more than the remaining amount on the gift card. Therefore, the gift card reduces the order total. In the most extreme case, the order total is reduced to 0. However, the prices and taxes of the remaining OrderItems are NOT affected by this and will keep their normal value. This means that the store owner still has to pay the correct taxes for the remaining OrderItems even when the order total is zero. Gift cards have to be added as the LAST OrderItem of an order.
#
#
# Coupons
# ----------
# Coupons are never sold. A single coupon with a single SKU can be published en masse in a newspaper. While a coupon turns into an OrderItem when scanned, unlike gift cards, it does not have a price by itself  (the price is always zero), but it DOES modify the price and taxes of the matching OrderItem.  Coupons come in three flavors: 1) percent rebate for the matching Item, 2) fixed amount off a matching Item, 3) buy X get Y for free, also for a matching Item. As has been said, in all 3 cases, each coupon will have the price of 0 but will reduce the price (and taxes) of exactly one other OrderItem. Coupons have to be added to an Order AFTER the matching Item. 
# If the Coupon is added before, no action will take place.
#
#
# OrderItem level rebates
# ----------
# A store owner can decide to give a percent rebate to a single OrderItem. This rebate will modify the price and taxes of the OrderItem in question.
#
#
# Order level rebates
# ----------
# A store owner can decide to give a percent rebate to all OrderItems of an Order (e.g. when there are many OrderItems). Since in many countries different product types have different tax percentages, this rebate is not applied directly to the Order total, but simply applied to every single OrderItem, as has been explained under "OrderItem level rebates". For this reason, tax calculation will be correct.
#
#
# Discounts
# ----------
# A discount is identical to "OrderItem level rebates" except that it is applied automatically, according to a time span, Item category, Item SKU, Item location, or all Items.
#
#
# Actions
# ----------
# A so-called Action can modify the price of an OrderItem in complex ways, relative to the price of the corresponding Item, and at the time the OrderItem is added to an order. Many stores use a Item database that is imported from external sources (e.g. wholesaler databases in CSV format). For various reasons, an imported Item price can be wrong (e.g. because the wholesaler lists a wrong price). However, it does not make sense to change the Item price manually, since a wholesaler update would overwrite the correction with the wrong price again. In this case, an Action has to be created for the 'wrong' Item price that always corrects it when the Item is sold. An action can add, subtract, multiply or divide a price by a specified factor. Actions also allow to 'program' more complex rules, like: "Reduce the price of an OrderItem when at least 6 Items of the same Category are added to an Order, by the cheapest OrderItem of those 6 scanned items." As already said, Actions modify the price and taxes of the OrderItem and the taxes will be correct.
#
#
# LoyaltyCard Points
# ----------
# This feature and the possibility to grant rebates based on a certain number of loyalty points has been removed.
#
#
#
# GROSS VERSUS NET VERSUS TAX
# ===========================
#
# Countries differ in the treatment of prices. For example, in the USA and Canada, prices of products are considered net, even though the customer owes and is shown on the customer display the gross amount. We will refer to this system as the "USA tax system".
#
# In other countries, like Europe, prices of products are considered gross, and the customer owes and is shown on the customer display also the gross amount. We will refer to this system as the "Europe tax system".
#
#
#
# EXPLANATION OF THE MODEL ATTRIBUTES
# ===================================
#
# Item
# ----------
#   base_price: The regular price of the product. For "net price system" this is the net amount. For "gross price system" this is the gross amount.
#
#
# OrderItem
# ----------
#  price: Identical to base_price of the belonging Item. This price will be modified by the following conditions: 1) will be inverted if OrderItem is set to buyback, 2) will by reduced by a percentage when an Action applies, 3) will be set to the price specified by an GS1 barcode when the flag "price_by_qty" of the belonging Item is not set, 4) in case of a gift card it will become the current order total, 5) in case the belonging Item has set the flag "calculate_part_price" the price will become the sum of all parts of that item.
#
#  quantity: self-explanatory
#
#  total: includes taxes
#
#  coupon_amount: ...
#
#  discount_amount: ...
#
#  rebate_amount: ...
#
#  tax: this is equal to the percentage of the belonging TaxProfile at the time of scanning the Item
#
#  tax_amount: ...
#
#
# Order
# ----------
#  total: includes taxes
#
#  tax_amount: sum of the tax_amount fields of ALL belonging OrderItems





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
  belongs_to :current_register_daily
  belongs_to :drawer
  belongs_to :tax_profile
  belongs_to :origin_country, :class_name => 'Country', :foreign_key => 'origin_country_id'
  belongs_to :destination_country, :class_name => 'Country', :foreign_key => 'destination_country_id'
  belongs_to :sale_type
  has_and_belongs_to_many :discounts


  monetize :total_cents, :allow_nil => true
  monetize :tax_amount_cents, :allow_nil => true
  monetize :cash_cents, :allow_nil => true
  monetize :lc_amount_cents, :allow_nil => true
  monetize :change_cents, :allow_nil => true
  monetize :payment_total_cents, :allow_nil => true
  monetize :noncash_cents, :allow_nil => true
  monetize :rebate_amount_cents, :allow_nil => true

  
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
    self.payment_methods.sum(:amount)
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
    self.update_attribute(:is_proforma, !self.is_proforma)
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
    if self.paid then
      log_action "Order is paid already, cannot edit"
    end
    
    # get existing regular item
    item = self.order_items.visible.where(:no_inc => nil, :sku => params[:sku]).first
    if item then
      if item.is_normal?
        log_action "Item is normal, and present, just increment"
        # simply increment and return
        item.quantity += 1        
        item.calculate_totals
        item.save
        self.calculate_totals
        return item
      else
        log_action "Item is not normal but is #{item.behavior}"
      end
    else
      log_action "Item not found on order"
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
    
    if i.class == Item and i.item_type.behavior == 'gift_card' and i.sku == "G000000000000"
      log_action "Dynamic Giftcard SKU detected"
      new_i = create_dynamic_gift_card_item
      i = new_i
    end
    
    # finally create the order item
    oi = OrderItem.new
    oi.order = self
    oi.set_attrs_from_item(i)
    if params[:sku].include?('.') or params[:sku].include?(',')
      log_action "Setting no_inc"
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
    i.tax_profile = zero_tax_profile
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
    
    pm = sku.match(/(\d{1,9}[\.\,]\d{1,2})/)
    if pm and pm[1]
      # a price in the format xx,xx was entered
      i.sku = "DMY" + Time.now.strftime("%y%m%d") + rand(999).to_s
      i.base_price = sku
    else
      # dummy item
      i.sku = sku
      i.base_price = 0
    end
    i.name = i.sku
    i.save
    return i
  end

 


  

  def calculate_totals
    log_action "Calculating Totals"
    
    _oi_total = self.order_items.visible.sum(:total_cents)
    _oi_tax_amount = self.order_items.visible.sum(:tax_amount_cents)
    
    log_action "Total is: #{_oi_total} and tax is #{_oi_tax_amount}"
   
    self.tax_amount_cents = _oi_tax_amount
    self.total_cents = _oi_total

    if not self.save then
      puts self.errors.full_messages.to_sentence
      raise "Order Could Not Be Saved"
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
    self.save
    
    self.update_item_quantities
    self.activate_giftcard_items
    self.update_giftcard_remaining_amounts
    self.create_payment_method_items(params)
    self.create_drawer_transaction
    self.update_timestamps
    
    
    if self.is_quote
      self.qnr = self.vendor.get_unique_model_number('quote')
    else
      self.nr = self.vendor.get_unique_model_number('order')
    end
    self.save
    
  end
  
  def update_timestamps
    self.order_items.update_all :completed_at => self.completed_at
  end
  
  def create_drawer_transaction
    add_amount = (self.cash - self.change)
    return if add_amount.zero?
    
    drawer = self.user.get_drawer
    
    dt = DrawerTransaction.new
    dt.vendor = self.vendor
    dt.company = self.company
    dt.user = self.user
    dt.cash_register = self.cash_register
    dt.order = self
    dt.complete_order = true
    dt.amount = add_amount
    dt.drawer = drawer
    dt.drawer_amount = drawer.amount
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
          if oi.is_buyback
            i.quantity += oi.quantity
            i.quantity_buyback += oi.quantity
          else
            i.quantity -= oi.quantity
            i.quantity_sold += oi.quantity
          end
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
      pmi.user = self.user
      pmi.drawer = self.drawer
      pmi.cash_register = self.cash_register
      pmi.amount = Money.new(SalorBase.string_to_float(v[:amount]) * 100.0)
      pmi.cash = pm.cash
      pmi.quote = pm.quote
      pmi.unpaid = pm.unpaid
      pmi.save
      
      self.payment_method_items << pmi
      self.is_quote = true if pm.quote == true
      self.is_unpaid = true if pm.unpaid == true
    end
    
    self.save
    
    payment_cash = Money.new(self.payment_method_items.visible.where(:cash => true).sum(:amount_cents))
    payment_total = Money.new(self.payment_method_items.visible.sum(:amount_cents))
    payment_noncash = (payment_total - payment_cash)
    change = (payment_total - self.total)
    change_payment_method = self.vendor.payment_methods.visible.find_by_change(true)

    pmi = PaymentMethodItem.new
    pmi.vendor = self.vendor
    pmi.company = self.company
    pmi.user = self.user
    pmi.drawer = self.drawer
    pmi.cash_register = self.cash_register
    pmi.amount = change
    pmi.change = true
    pmi.payment_method = change_payment_method
    pmi.save
    
    self.payment_method_items << pmi
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
  
  
  def report
    sum_taxes = Hash.new

    self.vendor.tax_profiles.visible.each { |t| sum_taxes[t.id] = {:total => 0, :letter => t.letter, :value => 0} }
    
    total = 0
    list_of_items = ''
    list_of_items_raw = []
    list_of_taxes_raw = []

    integer_format = "%s %-19.19s %6.2f  %3u   %6.2f\n"
    float_format = "%s %-19.19s %6.2f  %5.3f %6.2f\n"
    percent_format = "%s %-19.19s %6.1f%% %3u   %6.2f\n"
    tax_format = "   %s: %2i%% %7.2f %7.2f %8.2f\n"

    self.order_items.visible.each do |oi|
      name = oi.item.get_translated_name(I18n.locale)
      taxletter = oi.tax_profile.letter
      

      # --- NORMAL ITEMS ---
      if oi.behavior == 'normal'
        if oi.quantity == Integer(oi.quantity)
          # integer quantity
          list_of_items += integer_format % [taxletter, name, oi.price, oi.quantity, oi.total]
          list_of_items_raw << to_list_of_items_raw([taxletter, name, oi.price, oi.quantity, oi.total, 'integer'])
        else
          # float quantity (e.g. weighed OrderItem)
          list_of_items += float_format % [taxletter, name, oi.price, oi.quantity, oi.total]
          list_of_items_raw << to_list_of_items_raw([taxletter, name, oi.price, oi.quantity, oi.total, 'float'])
        end
      end

      # GIFT CARDS
      if oi.behavior == 'gift_card'
        list_of_items += "%s %-19.19s         %3u   %6.2f\n" % [taxletter, name, oi.quantity, oi.total]
        list_of_items_raw << to_list_of_items_raw([taxletter, name, nil, oi.quantity, oi.total, 'integer'])
      end

      # COUPONS
      if oi.behavior == 'coupon'
        list_of_items += "  %-19.19s         %3u\n" % [oi.item.name, oi.quantity]
        list_of_items_raw << to_list_of_items_raw([nil, oi.item.name, nil, oi.quantity, nil, 'integer'])
      end

      # DISCOUNTS
      if oi.discount_amount and not oi.discount_amount.zero? # TODO: get rid of nil values in DB
        discount = oi.discounts.first
        discount_blurb = I18n.t('printr.order_receipt.discount') + ' ' + oi.discount.to_s + ' %'
        list_of_items += "  %-19.19s         %3u\n" % [discount_blurb, oi.quantity] #TODO
        list_of_items_raw << to_list_of_items_raw([nil, discount_blurb, nil, oi.quantity, nil, 'integer'])
      end

      # REBATES
      if oi.rebate
        rebate_blurb = I18n.t('printr.order_receipt.rebate') + " " + oi.rebate.to_s + " %"
        list_of_items += "  %-19.19s         %3u\n" % [rebate_blurb, oi.quantity]
        list_of_items_raw << to_list_of_items_raw([nil, rebate_blurb, nil, oi.quantity, nil, 'integer'])
      end
    end


    # --- payment method items ---
    paymentmethods = Hash.new
    self.payment_method_items.visible.each do |pmi|
      next if pmi.amount.zero?
      blurb = pmi.payment_method.name
      blurb = I18n.t('printr.eod_report.refund') + ' ' + blurb if pmi.refund
      paymentmethods[pmi.id] = { :name => blurb, :amount => pmi.amount }
    end

    
    # --- taxes ---
    list_of_taxes = ''
    used_tax_amounts = self.order_items.visible.select("DISTINCT tax")
    used_tax_amounts.each do |r|
      tax_in_percent = r.tax # this is the tax in percent, stored on OrderItem
      tax_profile = self.vendor.tax_profiles.find_by_value(tax_in_percent)
      tax_amount = Money.new(self.order_items.visible.where(:tax => tax_in_percent).sum(:tax_amount_cents))
      total = Money.new(self.order_items.visible.where(:tax => tax_in_percent).sum(:total_cents))
      next if tax_amount.zero?
      list_of_taxes += tax_format % [tax_profile.letter, tax_in_percent, total - tax_amount, tax_amount, total]
      list_of_taxes_raw << to_list_of_taxes_raw([tax_profile.letter, tax_profile.value, total - tax_amount, tax_amount, total])
    end
    
    # --- invoice blurbs ---
    invoice_blurb_header = self.vendor.invoice_blurbs.visible.where(:lang => I18n.locale, :is_header => true).last
    invoice_blurb_footer = self.vendor.invoice_blurbs.visible.where(:lang => I18n.locale).where('is_header IS NOT TRUE').last
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
  
#   def sanity_check
#     if self.paid then
#       pms = self.payment_methods.collect { |pm| pm.internal_type}
#       if pms.include? "InCash" and not pms.include? "Change" and self.change_given > 0 then
#         puts "Order is missing Change Payment Method"
#         PaymentMethod.create(:vendor_id => self.vendor_id, :internal_type => 'Change', :amount => - self.change_given, :order_id => self.id)
#         self.payment_methods.reload
#       end
#       pms_seen = []
#       self.payment_methods.each do |pm|
#         if pms_seen.include? pm.internal_type then
#           puts "Deleting pm..."
#           pm.delete
#         else
#           pms_seen << pm.internal_type
#         end
#       end
#       self.payment_methods.reload
#     end
#   end
  
  def check
    messages = []
    tests = []
    
    if self.paid
      tests[1] = self.payment_methods.sum(:amount_cents) == self.total_cents
    end
    
    0.upto(tests.size-1).each do |i|
      messages << "Order #{ self.id }: test#{i} failed." if tests[i] == false
    end
    return messages
  end
  
  def self.check_range(from, to)
    orders = Order.where(:paid => 1, :created_at => from..to)
    
    messages = []
    tests = []
    
    orders.each do |o|
      messages << o.check
    
      0.upto(tests.size-1).each do |i|
        if tests[i] == false
          messages << "Order #{ o.id }: test#{i} failed." 
        else
          messages << []
        end
      end
    end
    return messages
  end

  # Mikey: not sure what this does, seems like fixing unsound orders. i think it would be better to fix the core logic instead of adding more and more sanity checks on top.
#   def run_new_sanitization
#     unsound = false
#     if params[:pm_id] then
#       pm = @order.payment_methods.find_by_id(params[:pm_id].to_s)
#       any = @order.payment_methods.find_by_internal_type('Unpaid')
#       if any and params[:pm_name] and not ['Unpaid','Change'].include? params[:pm_name] then
#         # it should not allow doubles of this type
#         if not @order.payment_methods.find_by_internal_type(params[:pm_name]) then
#           npm = PaymentMethod.new(:name => params[:pm_name],:internal_type => params[:pm_name], :amount => 0)
#           @order.payment_methods << npm
#           pm = npm
#           @order.save
#         end
#       end # end handling new pms by name
#       
#       if not pm.internal_type == 'Unpaid' then
#         pm.update_attribute :amount, params[:pm_amount]
#         diff = any.amount - pm.amount
#         if diff == 0 then
#           any.destroy
#           @order.update_attribute :unpaid_invoice, false
#         elsif diff < 0 then
#           raise "Cannot pay more than is due"
#         else
#           any.update_attribute :amount, diff
#         end
#       else
#         raise "Cannot because unsound"
#       end
#     end
#     @current_user = @order.user
#     if not @order.user then
#       @order.user = User.where(:vendor_id => @order.vendor_id).last
#       @order.save
#       @current_user = @order.user
#     end
#   end
  
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
      :order_items => self.order_items
    }
    if self.customer then
      attrs[:customer] = self.customer.json_attrs
      attrs[:loyalty_card] = self.customer.loyalty_cards.visible.last.json_attrs if self.customer.loyalty_cards.visible.last
    end
    attrs.to_json
  end
end
