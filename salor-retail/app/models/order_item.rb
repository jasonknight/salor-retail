# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class OrderItem < ActiveRecord::Base
  # {START}
  include SalorScope
  include SalorBase
  
  belongs_to :vendor
  belongs_to :company
  belongs_to :order
  belongs_to :user
  belongs_to :item
  belongs_to :tax_profile
  belongs_to :location
  belongs_to :item_type
  belongs_to :category
  has_and_belongs_to_many :discounts
  attr_accessor :is_valid
  has_many :coupons, :class_name => 'OrderItem', :foreign_key => :coupon_id
  belongs_to :order_item,:foreign_key => :coupon_id
  has_many :histories, :as => :user

  scope :sorted_by_modified, order('updated_at ASC')
  
  validate :validify
  
  def validify
    order = self.order
    errors.add(:order_id, 'cannot change anything since it belongs to a paid order') if order.paid == 1
  end
  
  def tax_profile_id=(id)
    tp = TaxProfile.find_by_id(id)
    if tp then
      write_attribute(:tax_profile_id,id)
      write_attribute(:tax_profile_amount,tp.value)
    end
  end
  def item_type_id=(id)
    write_attribute(:behavior,ItemType.find(id).behavior)
    write_attribute(:item_type_id,id)
  end
  def get_tax_profile_letter
    if self.item.tax_profile then
      return self.item.tax_profile.letter
    else
      return ''
    end
  end
  def get_translated_name(locale)
    if self.item then
      return self.item.get_translated_name(locale)
    else
      return 'NoItem'
    end
  end
  def get_category_name
    if self.category and self.category.name then
      return self.category.name
    else
      return "NoCategory"
    end
  end
  def get_location_name
    if self.item and self.item.location then
      return self.item.location.name
    else
      return 'NoLocation'
    end
  end
  
  def toggle_buyback(x)
    #ActiveRecord::Base.logger.info "Order.buy_order #{self.order.buy_order}"
    if self.is_buyback then
      self.update_attribute(:is_buyback,false)
      self.price = discover_price(self.item)
      calculate_total
    else
      if self.quantity > 1 then
        oi = self.clone
        oi.quantity = 1
        oi.order = self.order 
        oi.is_buyback = true if not self.order.buy_order == true
        oi.item = self.item
        oi.price = oi.discover_price(oi.item)
        oi.save
        self.quantity -= 1
        self.save
        return
      end
      self.update_attribute(:is_buyback,true) if not self.order.buy_order == true
      self.price = discover_price(self.item)
      calculate_total
    end
  end
  def create_refund_transaction(amount,type,opts)
    dt = DrawerTransaction.new(opts)
    dt[type] = true
    dt.amount = amount
    dt.drawer_id = @current_user.get_drawer.id
    dt.drawer_amount = @current_user.get_drawer.amount
    dt.order_id = self.order.id
    dt.order_item_id = self.id
    if dt.save then
      if type == :payout then
        @current_user.get_drawer.update_attribute(:amount,@current_user.get_drawer.amount - dt.amount)
      elsif type == :drop then
        @current_user.get_drawer.update_attribute(:amount,@current_user.get_drawer.amount + dt.amount)
      end
    else
      raise dt.errors.full_messages.inspect
    end
  end
  #
  def create_refund_payment_method(amount,refund_payment_method)
    PaymentMethod.create(:internal_type => (refund_payment_method + 'Refund'), 
                         :name => (refund_payment_method + 'Refund'), 
                         :amount => - amount, 
                         :order_id => self.order.id
        ) # end of PaymentMethod.create
  end
  
  #
  def toggle_refund(x, refund_payment_method)
    # -1 = Not Enough in Drawer
    # false is general failure
    # true is everything went according to plan  
    t = (self.calculate_total)
    if self.order and self.order.rebate > 0
      if self.order.rebate_type == "percent" then
        t -= t * ( self.order.rebate / 100.0 )
      end
      if self.order.rebate_type == "fixed" then
        # Distribute the fixed rebate equally on all OrderItems of the Order. Ugly, but this needs to be done so that the report generation is correct.
        t -= self.order.rebate / self.order.order_items.visible.count
      end
    end
    if self.order and self.order.lc_discount_amount > 0
      t -= self.order.lc_discount_amount / self.order.order_items.visible.count
    end
    if self.order.vendor.salor_configuration.calculate_tax == true
      # net price
      t += self.tax
    end
    
    if ((@current_user.get_drawer.amount - t) < 0 and refund_payment_method == 'InCash') then
      # do not fail. let the user do what he wants.
      #GlobalErrors.append_fatal("system.errors.not_enough_in_drawer",self)
      #return -1
    end

    q = self.quantity
    if self.refunded then
      return false
      # this is depreciated and should never happen right now since it's blocked by the orders#show view
    else
      self.update_attribute(:refunded,true)
      self.update_attribute(:refunded_by, @current_user.id)
      self.update_attribute(:refunded_by_type, @current_user.class.to_s)
      self.update_attribute(:refund_payment_method, refund_payment_method)
      update_location_category_item(t * -1, q * -1)
      self.order.update_attribute(:total, self.order.total - t)
      if refund_payment_method == 'InCash'
        if t < 0
          create_refund_transaction(-t,:drop, {:tag => 'OrderItemRefund', :is_refund => true, :notes => I18n.t("views.notice.order_refund_dt",:id => self.id)}) if not x.nil?
        else
          create_refund_transaction(t,:payout, {:tag => 'OrderItemRefund', :is_refund => true, :notes => I18n.t("views.notice.order_refund_dt",:id => self.id)}) if not x.nil?
        end
      else
        create_refund_payment_method(t,refund_payment_method) if not x.nil?
      end

      # @current_user.vendor.open_cash_drawer unless @current_register.salor_printer or self.order.refunded # open cash drawer only if not called from the Order.toggle_refund function # this is handled now by an onclick event in shared/_order_line_items_.html.erb
     return true
    end
    return false
  end
  def update_location_category_item(t,q)
    self.item.update_attribute(:quantity_sold, self.item.quantity_sold + q)
    self.item.update_attribute(:quantity, self.item.quantity + (-1 * q))
    loc = self.item.location
    cat = self.item.category
    if loc then
      loc.update_attribute(:quantity_sold,loc.quantity_sold + q)
      loc.update_attribute(:cash_made, loc.cash_made + t) 
    end
    if cat then
      cat.update_attribute(:quantity_sold, cat.cash_made + q)
      cat.update_attribute(:cash_made, cat.cash_made + t)
    end
  end
  def toggle_lock=(x)
    toggle_lock(x)
  end

  def toggle_lock(type)
    return # we no longer support locking
    if type == 'total' then
      self.update_attribute(:total_is_locked,!self.total_is_locked)
    elsif type == 'tax' then
      self.update_attribute(:tax_is_locked,!self.tax_is_locked)
    end
  end
  def price=(p)
    if self.order and self.order.paid == 1 then
      return
    end
    p = self.string_to_float(p)
    if (self.item.base_price == 0.0 or self.item.base_price == nil) and (self.item.must_change_price == false or self.item.behavior == 'gift_card') then
      self.item.update_attribute :base_price,p
      if self.item.behavior == 'gift_card' then
        self.item.update_attribute :amount_remaining, p
      end
    end
    if self.is_buyback == true and p > 0 then
      p = p * -1
    end
    if self.discounts.any? then
      damount = 0
      pstart = p * self.quantity
      self.discounts.each do |discount|
        if discount.amount_type == 'percent' then
          d = discount.amount / 100
          damount += (pstart * d)
        elsif discount.amount_type == 'fixed' then
          damount += discount.amount
        end
      end
      write_attribute(:discount_amount, damount)
      #self.calculate_total
    end
    write_attribute(:price,self.string_to_float(p)) #string_to_float SalorBase
  end
  # Proxy methods so that actions work
  def base_price=(p)
    self.price = p
  end
  def base_price
    self.price
  end
  def total=(p)
    if self.order and self.order.paid == 1 then
      return
    end
    p = self.string_to_float(p)
    if self.is_buyback == true and p > 0 then
      p = p * -1
    end
    write_attribute(:total,p) 
  end
  def tax=(p)
    if self.order and self.order.paid == 1 then
      return
    end
    write_attribute(:tax,self.string_to_float(p)) 
  end
  def quantity=(q)
    if self.order and self.order.paid == 1 then
      return
    end
    if q.nil? or q.blank? then
      q = 0
    end
    q = q.to_s.gsub(',','.')
    q = q.to_f.round(3)
    q = 0 if q < 0
    if self.discounts.any? then
      damount = 0
      pstart = self.price * q
      self.discounts.each do |discount|
        if discount.amount_type == 'percent' then
          d = discount.amount / 100
          damount += (pstart * d)
        elsif discount.amount_type == 'fixed' then
          damount += discount.amount
        end
      end
      write_attribute(:discount_amount, damount)
      #self.calculate_total
    end
    write_attribute(:quantity,q)
  end
  
  def set_attrs_from_item(item)
    return nil if self.order.paid
    # Copying Item attributes over to OrderItem attributes
    self.tax_profile = item.tax_profile
    self.vendor = item.vendor
    self.company = item.company
    self.item_type = item.item_type
    self.item = item
    self.weigh_compulsory = item.weigh_compulsory
    self.is_buyback = item.default_buyback
    self.category = item.category
    self.location = item.location
    self.behavior = item.behavior # acts as a cache
    self.tax_profile_amount = item.tax_profile.value
    self.amount_remaining = item.amount_remaining
    self.sku = item.sku
    self.activated = item.activated
    self.quantity = self.weigh_compulsory ? 0 : 1
    self.discover_price
    #self.save
    self.calculate_totals
  end


  def calculate_totals
    return nil if self.order.paid

    # COUPONS
    if self.behavior == 'coupon'
      self.total = self.price
      self.save
      return
    end

    # BUY ORDER, BUYBACK ITEM
    if self.order.buy_order or self.is_buyback
      self.total = self.price * self.quantity
      self.save
      return
    end

    # GIFT CARDS
    if self.behavior == 'gift_card'
      if self.item.activated
        if self.amount_remaining <= 0
          return 0
        end
        if self.price == 0 then
          self.price = self.amount_remaining
        end
        if self.price < 0 then
          self.price *= -1
        end
        if self.price > self.amount_remaining then
          self.price = self.amount_remaining
        end
        if self.price > 0 then
          p = self.price * -1
        else
          p = self.price
        end
        self.update_attribute(:price, self.price)
        self.update_attribute(:total,self.price)
        return p
      end
    end
    
    

    ttl = 0
    self.quantity = 0 if self.quantity.nil?
    if self.item.parts.any? and self.item.calculate_part_price then
      # PARTS
      self.item.parts.each do |part|
        ttl += part.base_price * part.part_quantity
      end
        ttl = ttl * self.quantity
    else
      ttl = self.price * self.quantity
    end
    
    # REFUNDS
    if self.refunded and ttl > 0 then
      ttl = ttl * -1
    end


    # COUPONS
    if self.order and self.order.coupon_for(self.item.sku) then
      cttl = 0
      self.order.coupon_for(self.item.sku).each do |c|
        cttl += c.coupon_total(ttl,self)
      end
      ttl -= cttl
    end
    if self.rebate then
      ttl -= (ttl * (self.rebate / 100.0))
    end
    if self.order and self.order.rebate then
      ttl -= (ttl * (self.order.rebate / 100.0))
    end

    # DISCOUNTS
    if self.discount_amount > 0 then
      ttl -= self.discount_amount
    end

    if not self.total == ttl and not self.total_is_locked then
      self.total = ttl.round(2)
      self.update_attribute(:total,ttl) # MF MOD
    end
    return self.total
  end
  
  
  
  
  
  
  
  def calculate_total_with_rebate(rebate = nil)
    # This calculates OrderItem total for ITEM rebate
    if rebate.nil? then
      rebate = self.rebate
    else
      self.rebate = rebate
    end
    rebate = 0 if rebate.nil?
    self.total = ((self.price * self.quantity) - (self.price * self.quantity * (rebate / 100.0))).round(2)
    return self.total
  end

  def calculate_rebate_amount
    self.rebate_amount = (self.price * self.quantity * (self.rebate / 100.0)).round(2)
  end

  def calculate_oi_order_rebate
    # This calculates ORDER rebate for % only for a given OrderItem
	  amnt = 0.0
	  self.total = 0 if self.total.nil?
    if self.order.rebate_type == 'percent' then
      amnt = self.total * (self.order.rebate / 100.0)
    end
    return amnt    
  end
  #
  def gross
    return self.total
  end
  #
  def calculate_tax(no_update = false)
    return 0 if self.tax_free == true or (self.order and self.order.tax_free == true)
    return 0 if self.refunded
    if self.activated and self.behavior == 'gift_card' then
      self.update_attribute(:tax,0) if self.tax != 0
      return 0
    end
    if self.behavior == 'coupon' then
      self.update_attribute(:tax,0) if self.tax != 0
      return 0 
    end
    self.tax = 0 if self.tax.nil?
    return self.tax if self.tax_is_locked
    return 0 if not self.tax_profile_amount
    p = self.total
    if $Conf and not $Conf.calculate_tax then
      net_price = (p *(100 / (100 + (100 * (self.tax_profile_amount/100))))).round(2);
      t = (p - net_price).round(2)
    else
      t = p * (self.tax_profile_amount/100.00)
    end
    if not t == self.tax and not self.tax_is_locked then #i.e. we get the total from above 
      # in order to not charge for buy 1 get one frees
      self.tax = t
      self.update_attribute(:tax,t) unless no_update == true
    end
    if self.tax.nil? then
      self.tax = t
    end
    return self.tax
  end
  #
  def coupon_total(ttl,oi)
    # #ActiveRecord::Base.logger.info "Coupon Total called ttl=#{ttl} type=#{self.item.coupon_type}"
    amnt = 0
    return 0 if ttl <= 0
    if self.quantity > oi.quantity then
      self.update_attribute(:quantity,oi.quantity)
      self.quantity = oi.quantity
    end

    if self.item.coupon_type == 1 then #percent off self type
      q = self.quantity
      amnt = (oi.price * quantity) * (self.price / 100)
    elsif self.item.coupon_type == 2 then #fixed amount off
      # #ActiveRecord::Base.logger.info "Coupon is fixed"
      if self.price > ttl then
        #add_salor_error("system.errors.self_fixed_amount_greater_than_total",:sku => self.item.sku, :item => self.item.coupon_applies)
        amnt = ttl * self.quantity
        # #ActiveRecord::Base.logger.info "Setting to ttl " + ttl.to_s
      else
        amnt = self.item.base_price * self.quantity
        # #ActiveRecord::Base.logger.info "Setting to self.total " + self.item.base_price.to_s
      end
      self.update_attribute(:total,amnt)
      # #ActiveRecord::Base.logger.info "Fixed amnt = " + amnt.to_s
    elsif self.item.coupon_type == 3 then #buy 1 get 1 free
      if oi.quantity > 1 then
        if self.quantity > 1 then
          # this takes place when you have more than one b1g1 coupon and mored
          # than one target item.l
          q = self.quantity
          q = (oi.quantity / 2).to_i
          amnt = (oi.price * q)
        else
          amnt = (oi.price * self.quantity)
        end
      else
        add_salor_error("system.errors.coupon_not_enough_items")
      end
      self.update_attribute(:total,amnt)
    else
      # #ActiveRecord::Base.logger.info "couldn't figure out coupon type"
    end
    oi.update_attribute(:coupon_amount,amnt)
    oi.update_attribute(:coupon_applied, true)
    # #ActiveRecord::Base.logger.info "## Updating Attribute to #{amnt}"
    if amnt > 0 then
      oi.coupons << self
      oi.save
    end
    return amnt
  end

  #
  def split
  end


  def discover_price
    if self.order.buy_order or self.is_buyback
      self.price = - item.buyback_price
      self.save
      return
    end

    if item.behavior == 'gift_card' and item.activated then
      self.price = item.amount_remaining
      self.save
      return
    elsif item.behavior == 'coupon' then
      self.price = item.base_price
      self.save
      return
    end

    self.price = item.base_price
    
    discounts = self.vendor.get_current_discounts
    discounts.each do |d|
      if (d.item_sku == item.sku and d.applies_to == 'Item') or
          (d.location_id == item.location_id and d.applies_to == 'Location') or
          (d.category_id == item.category_id and d.applies_to == 'Category') or
          (d.applies_to == 'Vendor' and d.amount_type == 'percent')

        self.discounts << d

        if d.amount_type == 'percent'
          self.discount_amount = self.price * d.amount / 100
        elsif d.amount_type == 'fixed'
          self.discount_amount = d.amount
        end
        self.price -= self.discount_amount
        self.discounts << d
        self.discount_applied = true
        self.save
      end
    end
  end

  #
  def to_json
    obj = {}
    if self.item then
      obj = {
        :name => self.get_translated_name(I18n.locale)[0..20],
        :sku => self.item.sku,
        :item_id => self.item_id,
        :activated => self.item.activated,
        :amount_remaining => self.item.amount_remaining,
        :coupon_type => self.item.coupon_type,
        :quantity => self.quantity,
        :price => self.price.round(2),
        :coupon_amount => -1 * self.coupon_amount.round(2),
        :total => self.total.round(2),
        :id => self.id,
        :behavior => self.behavior,
        :discount_amount => self.discount_amount.round(2) * -1,
        :locked => self.total_is_locked,
        :rebate => self.rebate.nil? ? 0 : self.rebate,
        :is_buyback => self.is_buyback,
        :weigh_compulsory => self.item.weigh_compulsory,
        :must_change_price => self.item.must_change_price,
        :weight_metric => self.item.weight_metric,
        :tax_profile_amount => self.tax_profile_amount,
        :action_applied => self.action_applied
      }
    end
    if self.behavior == 'gift_card' and self.activated then
      obj[:price] = obj[:price] * -1
    end
    return obj.to_json
  end
  
  def set_sold
    the_item = self.item
    # #ActiveRecord::Base.logger.info "My quantity is: #{self.quantity} and my #{self.behavior}"
    #
    # begin update the quantities of the item
    if the_item.ignore_qty == false and self.behavior == 'normal' and self.order.is_proforma == false then
      if self.order and self.order.buy_order then
        the_item.update_attribute(:quantity, the_item.quantity + self.quantity)
        the_item.update_attribute(:quantity_buyback, the_item.quantity_buyback + self.quantity)
      else
        the_item.update_attribute(:quantity, the_item.quantity - self.quantity)
        the_item.update_attribute(:quantity_sold, the_item.quantity_sold + self.quantity)
      end
    end
    # end update the quantities of the item
    #
    # begin Check Parts and update quantities
    	  if the_item.parts.any? then
        the_item.parts.each do |part|
          next if part.ignore_qty == true # i.e. we just ignore the qty
          part.quantity ||= 0
          next if self.order.is_proforma == true
          if self.order and self.order.buy_order then
            part.update_attribute(:quantity, part.quantity + part.part_quantity)
          else
            part.update_attribute(:quantity, part.quantity - part.part_quantity)
            
            # update statistics based on parts
            the_item = part
            if the_item.category then
              the_item.category.update_attribute(:quantity_sold, the_item.category.quantity_sold + the_item.part_quantity)
            end
            if the_item.location then
              the_item.location.update_attribute(:quantity_sold,the_item.location.quantity_sold + the_item.part_quantity)
            end
            
          end
        end
      end
    # end Check Parts and update quantities
  end
  def update_quantity_sold
    log_action("Updating quantity sold")
    if self.order.is_proforma == true
      log_action "Returning because order is_proforma"
      return
    end
    the_item = self.item
    log_action "the_item id is #{the_item.id}"
    if the_item.category then
      log_action "Updating category #{the_item.category.id}"
      the_item.category.update_attribute(:quantity_sold, the_item.category.quantity_sold + self.quantity)
      log_action "Updating category #{the_item.category.id} complete"
    end
    if the_item.location then
      log_action "Updating location #{the_item.location.id}"
      the_item.location.update_attribute(:quantity_sold,the_item.location.quantity_sold + self.quantity)
      log_action "Updating location #{the_item.location.id} complete"
    end
    if the_item.item_stocks.any? then
      log_action "Updating item_stocks"
      stock = the_item.item_stocks.first
      stock.update_attribute :location_quantity, stock.location_quantity - self.quantity
      log_action "ItemStocks updated"
    end
  end
  def update_cash_made
    log_action "Updating cash_made"
    if self.order.is_proforma == true
      log_action "Returning from cash_made because order is_proforma"
      return
    end
    the_item = self.item
    log_action "the_item id is #{the_item.id}"
    if the_item.category then
      the_item.category.cash_made ||= 0.0
      log_action "Updating category #{the_item.category.id}"
      the_item.category.update_attribute(:cash_made, the_item.category.cash_made + self.total)
      log_action "Updating category #{the_item.category.id} complete"
    end
    if the_item.location then
      the_item.location ||= 0.0
      log_action "Updating location #{the_item.location.id}"
      the_item.location.update_attribute(:cash_made, the_item.location.cash_made + self.total)
      log_action "Updating location #{the_item.location.id} complete"
    end
  end
  def recover_item
    i = Item.find_by_sku(self.sku)
    if i then
      self.item = i
      self.save
      return
    else
      i = Item.get_by_code(self.sku)
      i.item_type_id = self.item_type_id
      i.base_price = self.price
      i.save
      self.item = i
      self.save
    end
  end
  # {END}
end
