# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class Order < ActiveRecord::Base

	include SalorScope
  include SalorBase

  has_many :order_items
  has_many :payment_methods
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
  scope :last_seven_days, lambda { where(:created_at => 7.days.ago.utc...Time.now.utc) }
  scope :unpaid, lambda { 
    t = self.table_name
    where(" ( ( `#{t}`.paid IS NULL OR `#{t}`.paid = 0) AND ( `#{t}`.total > 0.0 AND `#{t}`.total IS NOT NULL )  OR  ( `#{t}`.paid = 1 AND `#{t}`.unpaid_invoice IS TRUE) )").where(:is_quote => false) 
  }
  scope :normal_orders, lambda {
      where(:is_quote => false, :is_proforma => false)
  }
  scope :normal_completed, lambda {
      normal_orders.where(:paid => 1)
  }
  scope :quotes, lambda {
    where(:is_quote => true, :paid => 1)
  }
  
  # These two associations are here for eager loading to speed things up
  has_many :coupons, :class_name => "OrderItem", :conditions => "behavior = 'coupon' and hidden != 1" 
  has_many :gift_cards, :class_name => "OrderItem", :conditions => "behavior = 'gift_card' and hidden != 1"

  I18n.locale = AppConfig.locale
  REBATE_TYPES = [
    [I18n.t('views.forms.percent_off'),'percent'],
    [I18n.t('views.forms.fixed_amount_off'),'fixed']
  ]
  
#   def as_csv
#     return attributes
#   end
  
  def amount_paid
    self.payment_methods.sum(:amount)
  end
  
  def nonrefunded_item_count
    self.order_items.visible.where(:refunded => nil).count
  end


  
  def loyalty_card
    if self.customer
      return self.customer.loyalty_card
    end
  end
  
  def rebate_type_display
    REBATE_TYPES.each do |rt|
      return rt[0] if rt[1] == self.rebate_type
    end
    return self.rebate_type
  end
  
  def toggle_buy_order=(x)
    self.buy_order = !self.buy_order
    self.order_items.visible.each do |oi|
      oi.toggle_buyback=(x)
    end
    self.calculate_totals
  end

  def toggle_tax_free=(x)
    if self.tax_profile
      self.tax_profile = nil
      self.tax = nil
      self.order_items.visible.each do |oi|
        oi.tax_profile = oi.item.tax_profile
        oi.tax = oi.tax_profile.value
        oi.calculate_totals
      end
    else
      zero_tax_profile = self.vendor.tax_profiles.visible.where(:value => 0).first
      raise "A TaxProfile with 0% is missing" unless zero_tax_profile
      self.tax_profile = zero_tax_profile
      self.tax = zero_tax_profile.value
      self.order_items.visible.each do |oi|
        oi.tax_profile = zero_tax_profile
        oi.tax = zero_tax_profile.value
        oi.calculate_totals
      end
    end
    self.calculate_totals
  end

  def toggle_is_proforma=(x)
    self.update_attribute(:is_proforma, !self.is_proforma)
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
    return if self.paid
    # get existing regular item
    item = self.order_items.visible.where(:no_inc => nil, :sku => params[:sku]).first
    if item
      if not (item.activated or item.is_buyback)
        # simply increment and return
        item.quantity += 1
        item.save
        return item
      end
    end
    
    # at this point, we know that the added order item is not yet in the order. so we add a new one
    i = self.get_item_by_sku(params[:sku])
    
    if i.class == LoyaltyCard then
      self.customer = i.customer
      self.tag = self.customer.full_name
      self.save
      # this is not to be added as an order item, so we return
      return i
    end
    
    if i.class == Item and i.item_type.behavior == 'gift_card' and i.sku == "G000000000000"
      # note that we work with a new item from now on
      i = create_dynamic_gift_card_item
    end
    
    # finally create the order item
    oi = OrderItem.new
    oi.order = self
    oi.set_attrs_from_item(i)
    oi.sku = params[:sku]
    oi.no_inc ||= params[:no_inc]
    oi.modify_price
    oi.calculate_totals
    self.order_items << oi
    self.calculate_totals
    
    return oi
  end

  
  
  def create_dynamic_gift_card_item
    zero_tax_profile = self.vendor.tax_profiles.visible.where(:value => 0).first
    raise "NoTaxProfileFound" if zero_tax_profile.nil?
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
      i.amount_remaining += gc.price
      i.amount_remaining = i.amount_remaining.round(2)
      i.save
    end
  end
  
  # called by complete
  def activate_giftcard_items
    gcs = self.order_items.visible.where(:behavior => 'gift_card', :activated => nil)
    gcs.each do |gc|
      i = gc.item
      i.activated = true
      i.save
    end
  end
  

  
  
  
  def get_item_by_sku(sku)    
    item = self.vendor.items.visible.find_by_sku(sku)
    return item if item # a sku was entered

    m = self.vendor.gs1_regexp.match(sku)
    item = self.vendor.items.visible.where(:is_gs1 => true).find_by_sku(m[1]) if m
    return item if item # a GS1 barcode was entered

    lcard = self.vendor.loyalty_cards.visible.find_by_sku(sku)
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
    # total contain only subtotal sum of normal items
    self.total = self.order_items.visible.where("NOT ( behavior = 'gift_card' AND activated = 1 )").sum(:subtotal).round(2)
    
    # subtotal contains everything
    self.subtotal = self.order_items.visible.sum(:subtotal).round(2)
    
    # subtotal will include order rebates
    self.save
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
    self.paid_at = Time.now
    
    if self.is_quote then
      self.qnr = self.vendor.get_unique_model_number('quote')
    else
      self.nr = self.vendor.get_unique_model_number('order')
    end
    
    
    
    self.save
    
    self.update_item_quantities
    self.activate_giftcard_items
    self.update_giftcard_remaining_amounts
    self.create_payment_methods(params)
    
    dt = DrawerTransaction.new
    dt.vendor = self.vendor
    dt.company = self.company
    dt.user = self.user
    dt.order = self
    dt.complete_order = true
    dt.amount = self.cash - self.change
    dt.drawer_amount = self.user.get_drawer.amount
    dt.drawer = self.user.get_drawer
    dt.save
    
    self.save
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
            i.quantity_buyback += self.quantity
          else
            i.quantity -= oi.quantity
            i.quantity_sold += oi.quantity
          end
        end
        i.save
      end
    end
  end
  

  
  def create_payment_methods(params)
    self.payment_methods.delete_all
    self.vendor.payment_methods_types_list.each do |pmt|
      pt = pmt[1]
      if params[pt.to_sym] and not params[pt.to_sym].blank? and not SalorBase.string_to_float(params[pt.to_sym]) == 0
        
        if pt == 'Unpaid'
          self.unpaid_invoice = true
        end
        
        if pt == 'Quote'
          self.is_quote = true
        end
        
        pm = PaymentMethod.new
        pm.vendor = self.vendor
        pm.company = self.company
        pm.internal_type = pt
        pm.user = self.user
        pm.amount = SalorBase.string_to_float(params[pt.to_sym]).round(2)
        pm.save
        self.payment_methods << pm
      end
    end
    
    self.save
    
    payment_cash = self.payment_methods.visible.where(:internal_type => 'InCash').sum(:amount).round(2)
    payment_total = self.payment_methods.visible.sum(:amount).round(2)
    payment_noncash = (payment_total - payment_cash).round(2)
    change = (payment_total - self.subtotal).round(2)
                                  
    pm = PaymentMethod.new
    pm.vendor = self.vendor
    pm.company = self.company
    pm.internal_type = 'Change'
    pm.amount = change
    pm.user = self.user
    pm.save
    
    self.payment_methods << pm
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
  

  

#   def to_list_of_items_raw(array)
#     ret = {}
#     i = 0
#     [:letter,:name,:price,:quantity,:total,:type].each do |k|
#       ret[k] = array[i]
#       i += 1
#     end
#     return ret
#   end
  
  
  def get_report
    # sum_taxes is the taxable sum of money charged by the system
    sum_taxes = Hash.new
    # we turn sum_taxes into a hash of hashes 
    self.vendor.tax_profiles.visible.each { |t| sum_taxes[t.id] = {:total => 0, :letter => t.letter, :value => 0} }
    subtotal1 = 0
    discount_subtotal = 0
    rebate_subtotal = 0
    refund_subtotal = 0
    coupon_subtotal = 0
    list_of_items = ''
    list_of_items_raw = []
    list_of_taxes_raw = []
    list_of_order_items = []

    integer_format = "%s %-19.19s %6.2f  %3u   %6.2f\n"
    float_format = "%s %-19.19s %6.2f  %5.3f %6.2f\n"
    percent_format = "%s %-19.19s %6.1f%% %3u   %6.2f\n"
    tax_format = "   %s: %2i%% %7.2f %7.2f %8.2f\n"

    self.order_items.visible.each do |oi|
      list_of_order_items << oi
      item_total = 0 if item_total.nil?
      oi.price = 0 if oi.price.nil?
      oi.quantity = 0 if oi.quantity.nil?
      item_price = 0 if item_price.nil?
      name = oi.item.get_translated_name(I18n.locale)

      # Price calculation for normal items
      if oi.behavior == 'normal'
        item_price = oi.price
        item_price *= -1 if self.buy_order
        item_total = item_price * oi.quantity # total cannot be changed and locked any more
      end # passing

      # Price calculation for gift card items
      if oi.behavior == 'gift_card'
        if oi.activated
          # gift card as payment
          item_price = - oi.total
        else
          # gift card sold
          item_price = oi.total
        end
        item_total = item_price * oi.quantity
      end

      # Price calculation for coupon items
      if oi.behavior == 'coupon'
        # current OrderItem is a coupon
        if oi.item.coupon_type == 1
          # parent item has a % coupon set
          item_price = oi.price
          item_total = (- oi.order_item.price * oi.price / 100.0) * oi.quantity # calculation does not rely on other model code, so this is a test
        elsif oi.item.coupon_type == 2
          # parent item has a fixed price coupon set
          item_price = - oi.price # calculation does not rely on other model code, so this is a test
          # item_price = oi.coupon_amount # second possibility to get item_price
          item_total = item_price * oi.quantity
        elsif oi.item.coupon_type == 3
          # parent item has a b1g1 price coupon set
          item_price = - (oi.order_item.price)
          item_total = Integer(oi.order_item.quantity / 2) * item_price
        end
        coupon_subtotal += item_total
        subtotal1 -= item_total # subtotal1 is without any subtractions, so add it again
      end

      # these will accumulate discounts and rebates further down and are needed for tax and refund total calculation
      new_item_price = item_price
      new_item_total = item_total

      # Price calculation for discounts, a separate line will be added below so no modification of item_total
      if oi.discount_applied and not self.buy_order
        discount_price = - oi.discount_amount / oi.quantity
        discount_total = - oi.discount_amount
        new_item_price += discount_price
        new_item_total += discount_total
        if oi.refunded
          discount_price = 0
          discount_total = 0
        end
        discount_subtotal += discount_total
      end

      # Price calculation for rebates, a separate line will be added below so no modification of item_total
      # MF: Diversion between models and this calculation: buyback items with rebates (which does't make sense and nobody will ever use 
      if oi.rebate and oi.rebate > 0
        rebate_price = - ( oi.price * oi.rebate / 100.0)
        rebate_total = rebate_price * oi.quantity
        new_item_price += rebate_price
        new_item_total += rebate_total
        if oi.refunded
          rebate_price = 0
          rebate_total = 0
        end
        rebate_subtotal += rebate_total
      end

      # Price calculation for refunds
      if oi.refunded or ( oi.order_item and oi.order_item.refunded) then
        if not oi.item_type_id == 3
          # this is somewhat of a hack, which would be fixed if coupons would be refunded together with it's OrderItem
          refund_subtotal -= ( item_total - oi.discount_amount - oi.coupon_amount - oi.rebate_amount )
        end
        if self.rebate > 0
          if self.rebate_type == 'percent'
            refund_subtotal += new_item_total * ( 1 - ( 1 - self.rebate / 100.0 ))
          end
          if self.rebate_type == 'fixed'
            refund_subtotal += self.rebate / self.order_items.visible.count
          end
        end
        if self.lc_discount_amount > 0
          refund_subtotal += self.lc_discount_amount /  self.order_items.visible.count
        end
        item_price = 0
        item_total = 0
        new_item_price = 0
        new_item_total = 0
      end

      subtotal1 += item_total

      # Price calculation for taxes
      if not oi.refunded
        sum_taxes[oi.tax_profile_id][:total] += new_item_total # start with unmodified price
        # we can get away with this because it is highly unlikely that the value attribute on a TP changed mid order.
        sum_taxes[oi.tax_profile_id][:value] = oi.tax_profile_amount 
        if self.rebate > 0
          if self.rebate_type == 'percent'
            # distribute % order rebate euqally on all order items
            sum_taxes[oi.tax_profile_id][:total] -= new_item_total * ( 1 - ( 1 - self.rebate / 100.0 ))
          end
          if self.rebate_type == 'fixed'
            # distribute fixed order rebate euqally on all order items
            sum_taxes[oi.tax_profile_id][:total] -= self.rebate / self.order_items.visible.count
          end
        end
        if self.lc_points?
          lc_points_discount = - self.vendor.salor_configuration.dollar_per_lp * self.lc_points
          sum_taxes[oi.tax_profile_id][:total] += lc_points_discount / self.order_items.visible.count
        end
      end

      # THE FOLLOWING IS THE LINE GENERATION

      # NORMAL ITEMS
      if oi.behavior == 'normal'
        if oi.quantity == Integer(oi.quantity)
          # integer quantity
          list_of_items += integer_format % [oi.get_tax_profile_letter, name, item_price, oi.quantity, item_total]
          list_of_items_raw << to_list_of_items_raw([oi.get_tax_profile_letter, name, item_price, oi.quantity, item_total, 'integer'])
        else
          # float quantity (e.g. weighed OrderItem)
          list_of_items += float_format % [oi.get_tax_profile_letter, name, item_price, oi.quantity, item_total]
          list_of_items_raw << to_list_of_items_raw([oi.get_tax_profile_letter, name, item_price, oi.quantity, item_total, 'float'])
        end
      end

      # GIFT CARDS
      if oi.behavior == 'gift_card'
        list_of_items += integer_format % [oi.get_tax_profile_letter, name, item_price, oi.quantity, item_total]
        list_of_items_raw << to_list_of_items_raw([oi.get_tax_profile_letter, name, item_price, oi.quantity, item_total, 'integer'])
      end

      # COUPONS
      if oi.behavior == 'coupon'
        if oi.item.coupon_type == 1
          # percent coupon
          list_of_items += percent_format % [oi.get_tax_profile_letter, name, item_price, oi.quantity, item_total]
          list_of_items_raw << to_list_of_items_raw([oi.get_tax_profile_letter, name, item_price, oi.quantity, item_total, 'percent'])
        elsif oi.item.coupon_type == 2
          # fixed amount coupon
          list_of_items += integer_format % [oi.get_tax_profile_letter, name, item_price, oi.quantity, item_total]
          list_of_items_raw << to_list_of_items_raw([oi.get_tax_profile_letter, name, item_price, oi.quantity, item_total, 'integer'])
        elsif oi.item.coupon_type == 3
          # b1g1 coupon
          list_of_items += integer_format % [oi.get_tax_profile_letter, name, item_price, oi.quantity, item_total]
          list_of_items_raw << to_list_of_items_raw([oi.get_tax_profile_letter, name, item_price, oi.quantity, item_total, 'integer'])
        end
      end

      # DISCOUNTS
      if oi.discount_applied and not self.buy_order
        discount_name = I18n.t('printr.order_receipt.discount') + ' ' + oi.discounts.first.name
        if oi.quantity == Integer(oi.quantity)
          # integer quantity
          list_of_items += integer_format % [oi.get_tax_profile_letter, discount_name, discount_price, oi.quantity, discount_total]
          list_of_items_raw << to_list_of_items_raw([oi.get_tax_profile_letter, discount_name, discount_price, oi.quantity, discount_total, 'integer'])
        else
          # float quantity
          list_of_items += float_format % [oi.get_tax_profile_letter, discount_name, discount_price, oi.quantity, discount_total]
          list_of_items_raw << to_list_of_items_raw([oi.get_tax_profile_letter, discount_name, discount_price, oi.quantity, discount_total, 'float'])
        end
      end

      # REBATES
      if oi.rebate and oi.rebate > 0
        if oi.quantity == Integer(oi.quantity)
          # integer quantity
          list_of_items += integer_format % [oi.get_tax_profile_letter, I18n.t('printr.order_receipt.rebate'), rebate_price, oi.quantity, rebate_total]
          list_of_items_raw << to_list_of_items_raw([oi.get_tax_profile_letter, I18n.t('printr.order_receipt.rebate'), rebate_price, oi.quantity, rebate_total, 'integer'])
        else
          # float quantity
          list_of_items += float_format % [oi.get_tax_profile_letter, I18n.t('printr.order_receipt.rebate'), rebate_price, oi.quantity, rebate_total]
          list_of_items_raw << to_list_of_items_raw([oi.get_tax_profile_letter, I18n.t('printr.order_receipt.rebate'), rebate_price, oi.quantity, rebate_total, 'float'])
        end
      end

    end # order_items.each do


    if self.lc_discount_amount > 0
      lc_points_discount = - self.lc_discount_amount * (self.nonrefunded_item_count.to_f / self.order_items.visible.count.to_f )
      lc_points_count = self.lc_points * (self.nonrefunded_item_count.to_f / self.order_items.visible.count.to_f )
      subtotal1 += lc_points_discount
    end

    display_subtotal1 = not(self.rebate.zero? and discount_subtotal.zero? and rebate_subtotal.zero? and coupon_subtotal.zero?)

    subtotal2 = subtotal1
    subtotal2 += discount_subtotal if not discount_subtotal.zero?

    subtotal3 = subtotal2
    subtotal3 += rebate_subtotal if not rebate_subtotal.zero?

    subtotal4 = subtotal3
    subtotal4 += coupon_subtotal if not coupon_subtotal.zero?


    order_rebate = 0
    if self.rebate_type == 'percent' and not self.rebate.zero?
      percent_rebate_amount = - subtotal4 * self.rebate / 100.0
      percent_rebate = self.rebate
      order_rebate = percent_rebate_amount
    elsif self.rebate_type == 'fixed' and not self.rebate.zero?
      fixed_rebate_amount = - self.rebate * (self.nonrefunded_item_count.to_f / self.order_items.visible.count.to_f )
      order_rebate = fixed_rebate_amount
    end
    subsubtotal = subtotal4 + order_rebate
    


    paymentmethods = Hash.new
    self.payment_methods.each do |pm|
      next if pm.amount.zero?
      paymentmethods[pm.name] = pm.amount
    end

    list_of_taxes = ''
    # TaxProfiles are not immutable, counting on them to not be hidden/deleted or changed
    # may lead to some small errors. 
    # additionally, TaxProfiles not being immutable means we cannot use their value
    # attribute because it can change overtime.
    # When it comes to a report it is perhaps better to think in terms of
    # what the system charged them for taxes instead of what it should or should not be. 
    # because we don't allow for the deletion of TaxProfiles anymore, we just hid them
    # we can get away with using all for the time being 
    # TaxProfile.scopied.each do |tax|
    TaxProfile.all.each do |tax|
      next if sum_taxes[tax.id] == nil or sum_taxes[tax.id][:total] == 0
      # I.E. what is the percentage decimal of the tax value
      fact = sum_taxes[tax.id][:value] / 100.00
      if self.tax_free == true
        net =  sum_taxes[tax.id][:total]
        gro =  sum_taxes[tax.id][:total]
      else
        # How much of the sum goes to the store after taxes
        if $Conf and not $Conf.calculate_tax then
          net = sum_taxes[tax.id][:total] / (1.00 + fact)
          gro = sum_taxes[tax.id][:total]
        else
          # I.E. The net total is the item total because the tax is outside that price.
          net = sum_taxes[tax.id][:total]
          gro = sum_taxes[tax.id][:total] * (1 + fact)
        end
      end
      # The amount of taxes paid is the gross minus the net total
      vat = gro - net
      list_of_taxes += tax_format % [tax.letter,sum_taxes[tax.id][:value],net,vat,gro]
      list_of_taxes_raw << {:letter => tax.letter, :value => sum_taxes[tax.id][:value], :net => net, :tax => vat, :gross => gro}
    end

    if self.customer
      customer = Hash.new
      customer[:company_name] = self.customer.company_name
      customer[:first_name] = self.customer.first_name
      customer[:last_name] = self.customer.last_name
      customer[:street1] = self.customer.street1
      customer[:street2] = self.customer.street2
      customer[:postalcode] = self.customer.postalcode
      customer[:tax_number] = self.customer.tax_number
      customer[:city] = self.customer.city
      customer[:country] = self.customer.country
      customer[:current_loyalty_points] = self.loyalty_card.points
    end

    report = Hash.new
    report[:order_items] = list_of_order_items
    report[:discount_subtotal] = discount_subtotal
    report[:rebate_subtotal] = rebate_subtotal
    report[:refund_subtotal] = refund_subtotal
    report[:coupon_subtotal] = coupon_subtotal
    report[:list_of_items] = list_of_items
    report[:list_of_items_raw] = list_of_items_raw
    report[:lc_points_discount] = lc_points_discount
    report[:lc_points] = lc_points_count
    report[:subtotal1] = subtotal1
    report[:subtotal2] = subtotal2
    report[:subtotal3] = subtotal3
    report[:subtotal4] = subtotal4
    report[:percent_rebate_amount] = percent_rebate_amount
    report[:percent_rebate] = percent_rebate
    report[:fixed_rebate_amount] = fixed_rebate_amount
    report[:subsubtotal] = self.gross
    report[:paymentmethods] = paymentmethods
    report[:change_given] = self.change_given
    report[:list_of_taxes] = list_of_taxes
    report[:list_of_taxes_raw] = list_of_taxes_raw
    report[:customer] = customer
    report[:unit] = I18n.t('number.currency.format.friendly_unit')

    return report
  end
  
 
  
#   def inspectify
#     txt = "Order[#{self.id}]"
#     [:total,:subtotal,:tax,:gross].each do |f|
#        txt += " #{f}=#{self.send(f)}"
#     end
#     self.order_items.each do |oi|
#       txt += "\n\tOrderItem[#{oi.id}]"
#       [:quantity,:price,:total,:amount_remaining,:activated].each do |f|
#         txt += " #{f}=#{oi.send(f)}"
#       end
#     end
#     return txt
#   end
  
  
  def escpos_receipt(report)
    vendor = self.vendor
    
    friendly_unit = report[:unit]

    vendorname =
    "\e@"     +  # Initialize Printer
    "\e!\x38" +  # doube tall, double wide, bold
    vendor.name + "\n"

    locale = I18n.locale
    if locale
      tmp = InvoiceBlurb.where(:lang => locale, :vendor_id => self.vendor_id, :is_header => true)
      if tmp.first then
        receipt_blurb_header = tmp.first.body_receipt
      end
      tmp = InvoiceBlurb.where(:lang => locale, :vendor_id => self.vendor_id).where('is_header IS NOT TRUE')
      if tmp.first then
        receipt_blurb_footer = tmp.first.body_receipt
      end
    end
    receipt_blurb_header ||= vendor.salor_configuration.receipt_blurb
    receipt_blurb_footer ||= vendor.salor_configuration.receipt_blurb_footer
    
    receiptblurb_header = ''
    receiptblurb_header +=
    "\e!\x01" +  # Font B
    "\ea\x01" +  # center
    "\n" + receipt_blurb_header.to_s + "\n"
    
    receiptblurb_footer = ''
    receiptblurb_footer = 
    "\ea\x01" +  # align center
    "\e!\x00" + # font A
    "\n" + receipt_blurb_footer.to_s + "\n"
    
    header = ''
    header +=
    "\ea\x00" +  # align left
    "\e!\x01" +  # Font B
    I18n.t("receipts.invoice_numer_X_at_time", :number => self.nr, :datetime => I18n.l(self.created_at, :format => :iso)) + ' ' + self.current_register.name + "\n"

    header += "\n\n" +
    "\e!\x00" +  # Font A
    "\xc4" * 42 + "\n"

    list_of_items = report[:list_of_items]
    list_of_items += "\xc4" * 42 + "\n"
    
    lc_points_discount = ''
    unless report[:lc_points_discount].zero?
      lc_points_discount += "  %19.19s        %4u %8.2f\n" % [I18n.t('printr.order_receipt.lc_points_substracted'), report[:lc_points], report[:lc_points_discount]]
      lc_points_discount += "\xc4" * 42 + "\n"
    end
    
    discount_subtotal = ''
    unless report[:discount_subtotal].zero?
      discount_subtotal += "%29s %s %8.2f\n" % [I18n.t('printr.order_receipt.subtotal1'), report[:unit], report[:subtotal1]]
      discount_subtotal += "%29s %s %8.2f\n" % [I18n.t('printr.order_receipt.discount_subtotal'), report[:unit], report[:discount_subtotal]]
      discount_subtotal += "\xc4" * 42 + "\n"
    end
    
    item_rebate_subtotal = ''
    unless report[:rebate_subtotal].zero?
      item_rebate_subtotal += "%29s %s %8.2f\n" % [I18n.t('printr.order_receipt.subtotal2'), report[:unit], report[:subtotal2]]
      item_rebate_subtotal += "%29s %s %8.2f\n" % [I18n.t('printr.order_receipt.rebate_subtotal'), report[:unit], report[:rebate_subtotal]]
      item_rebate_subtotal += "\xc4" * 42 + "\n"
    end
    
    coupon_subtotal = ''
    unless report[:coupon_subtotal].zero?
      coupon_subtotal += "%29s %s %8.2f\n" % [I18n.t('printr.order_receipt.subtotal3'), report[:unit], report[:subtotal3]]
      coupon_subtotal += "%29s %s %8.2f\n" % [I18n.t('printr.order_receipt.coupon_subtotal'), report[:unit], report[:coupon_subtotal]]
      coupon_subtotal += "\xc4" * 42 + "\n"
    end
    
    order_rebate_subtotal = ''
    if report[:percent_rebate_amount]
      order_rebate_subtotal += "%29s %s %8.2f\n" % [I18n.t('printr.order_receipt.subtotal4'), report[:unit], report[:subtotal4]]
      order_rebate_subtotal += "%25.25s %2i%% %s %8.2f\n" % [I18n.t('printr.order_receipt.rebate_percent'), report[:percent_rebate], report[:unit], report[:percent_rebate_amount]]
      order_rebate_subtotal += "\xc4" * 42 + "\n"
    elsif report[:fixed_rebate_amount]
      order_rebate_subtotal += "%29s %s %8.2f\n" % [I18n.t('printr.order_receipt.subtotal4'), report[:unit], report[:subtotal4]]
      order_rebate_subtotal += "%29.29s %s %8.2f\n" % [I18n.t('printr.order_receipt.rebate_fixed'), report[:unit], report[:fixed_rebate_amount]]
      order_rebate_subtotal += "\xc4" * 42 + "\n"
    end
    
    subsubtotal = ''
    subsubtotal += "%29.29s %s %8.2f\n" % [I18n.t('printr.order_receipt.subsubtotal'), report[:unit], report[:subsubtotal]]
    
    paymentmethods = "\n"
    if report[:refund_subtotal].zero?
      paymentmethods += report[:paymentmethods].to_a.collect do |pm|
        "%29.29s %s %8.2f\n" % [pm[0], report[:unit], pm[1]]
      end.join
    else
      paymentmethods += "%29.29s %s %8.2f\n" % [I18n.t('printr.order_receipt.refunded'), report[:unit], report[:refund_subtotal]]
    end

    tax_format = "\n\n" +
    "\ea\x01" +  # align center
    "\e!\x01" # Font A
    tax_header = "         %5.5s     %4.4s  %6.6s\n" % [I18n.t('printr.order_receipt.net'), I18n.t('printr.order_receipt.tax'),
 I18n.t('printr.order_receipt.gross')]
    list_of_taxes = report[:list_of_taxes]
 
    customer = ''
    if report[:customer]
       customer += "%s\n%s %s\n%s\n%s %s\n%s" % [report[:customer][:company_name], report[:customer][:first_name], report[:customer][:last_name], report[:customer][:street1], report[:customer][:postalcode], report[:customer][:city], report[:customer][:tax_number]]
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
        lc_points_discount +
        discount_subtotal +
        item_rebate_subtotal +
        coupon_subtotal +
        order_rebate_subtotal +
        subsubtotal +
        paymentmethods +
        tax_format +
        tax_header +
        list_of_taxes +
        customer +
        receiptblurb_footer +
        duplicate +
        "\n" +
        footerlogo +
        "\n\n\n\n\n\n" + 
        "\x1D\x56\x00" +
        "\x1D\x61\x01"
    return { :text => output_text, :raw_insertations => raw_insertations }
  end
  
  def print
    vendor_printer = VendorPrinter.new :path => @current_register.thermal_printer
    print_engine = Escper::Printer.new('local', vendor_printer)
    print_engine.open
    
    contents = self.escpos_receipt(self.get_report)
    bytes_written, content_written = print_engine.print(0, contents[:text], contents[:raw_insertations])
    print_engine.close
    Receipt.create(:user_id => self.user_id, :current_register_id => self.current_register_id, :content => contents[:text], :order_id => self.id)
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
      tests[1] = self.payment_methods.sum(:amount).round(2) == self.total.round(2)
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
  
  def to_json
    self.total = 0 if self.total.nil?
    attrs = {
      :total => self.subtotal.to_f.round(2),
      :rebate_type => self.rebate_type_display,
      :rebate => self.rebate.to_f.round(2),
      :lc_points => self.lc_points,
      :id => self.id,
      :buy_order => self.buy_order,
      :tag => self.tag.nil? ? I18n.t("system.errors.value_not_set") : self.tag,
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
      attrs[:loyalty_card] = self.customer.loyalty_card.json_attrs
    end
    attrs.to_json
  end
end
