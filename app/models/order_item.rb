# ------------------- Salor Point of Sale ----------------------- 
# An innovative multi-user, multi-store application for managing
# small to medium sized retail stores.
# Copyright (C) 2011-2012  Jason Martin <jason@jolierouge.net>
# Visit us on the web at http://salorpos.com
# 
# This program is commercial software (All provided plugins, source code, 
# compiled bytecode and configuration files, hereby referred to as the software). 
# You may not in any way modify the software, nor use any part of it in a 
# derivative work.
# 
# You are hereby granted the permission to use this software only on the system 
# (the particular hardware configuration including monitor, server, and all hardware 
# peripherals, hereby referred to as the system) which it was installed upon by a duly 
# appointed representative of Salor, or on the system whose ownership was lawfully 
# transferred to you by a legal owner (a person, company, or legal entity who is licensed 
# to own this system and software as per this license). 
#
# You are hereby granted the permission to interface with this software and
# interact with the user data (Contents of the Database) contained in this software.
#
# You are hereby granted permission to export the user data contained in this software,
# and use that data any way that you see fit.
#
# You are hereby granted the right to resell this software only when all of these conditions are met:
#   1. You have not modified the source code, or compiled code in any way, nor induced, encouraged, 
#      or compensated a third party to modify the source code, or compiled code.
#   2. You have purchased this system from a legal owner.
#   3. You are selling the hardware system and peripherals along with the software. They may not be sold
#      separately under any circumstances.
#   4. You have not copied the software, and maintain no sourcecode backups or copies.
#   5. You did not install, or induce, encourage, or compensate a third party not permitted to install 
#      this software on the device being sold.
#   6. You have obtained written permission from Salor to transfer ownership of the software and system.
#
# YOU MAY NOT, UNDER ANY CIRCUMSTANCES
#   1. Transmit any part of the software via any telecommunications medium to another system.
#   2. Transmit any part of the software via a hardware peripheral, such as, but not limited to,
#      USB Pendrive, or external storage medium, Bluetooth, or SSD device.
#   3. Provide the software, in whole, or in part, to any thrid party unless you are exercising your
#      rights to resell a lawfully purchased system as detailed above.
#
# All other rights are reserved, and may be granted only with direct written permission from Salor. By using
# this software, you agree to adhere to the rights, terms, and stipulations as detailed above in this license, 
# and you further agree to seek to clarify any right not directly spelled out herein. Any right, not directly 
# covered by this license is assumed to be reserved by Salor, and you agree to contact an official Salor repre-
# sentative to clarify any rights that you infer from this license or believe you will need for the proper 
# functioning of your business.
class OrderItem < ActiveRecord::Base
  include SalorScope
  include SalorBase
  include SalorError
  include SalorModel
  belongs_to :order
  belongs_to :item
  belongs_to :tax_profile
  belongs_to :item_type
  belongs_to :category
  has_and_belongs_to_many :discounts
  attr_accessor :is_valid
  has_many :coupons, :class_name => 'OrderItem', :foreign_key => :coupon_id
  belongs_to :order_item,:foreign_key => :coupon_id

  scope :sorted_by_modified, order('updated_at ASC')
  
  # To speed things up, we cache the discounts
  def self.reload_discounts
  end
  def OrderItem.get_discounts
    Discount.scopied.select("amount,item_sku,id,location_id,category_id,applies_to,amount_type").where(["start_date <= ? and end_date >= ?",Time.now,Time.now])
  end
  def toggle_buyback(x)
    puts "Order.buy_order #{self.order.buy_order}"
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
    dt.drawer_id = GlobalData.salor_user.get_drawer.id
    dt.drawer_amount = GlobalData.salor_user.get_drawer.amount
    dt.order_id = self.order.id
    dt.order_item_id = self.id
    if dt.save then
      if type == :payout then
        GlobalData.salor_user.get_drawer.update_attribute(:amount,GlobalData.salor_user.get_drawer.amount - dt.amount)
      elsif type == :drop then
        GlobalData.salor_user.get_drawer.update_attribute(:amount,GlobalData.salor_user.get_drawer.amount + dt.amount)
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
    if not $User.get_drawer.amount >= self.total then
      GlobalErrors.append_fatal("system.errors.not_enough_in_drawer",self)
      return
    end

    t = (self.calculate_total)
    return if (GlobalData.salor_user.get_drawer.amount - t) < 0
    q = self.quantity
    if self.refunded then
      # this should never happen right now since it's blocked by the orders#show view
      #self.update_attribute(:refunded,false)
      #update_location_category_item(t,q)
      #opts = {:tag => I18n.t("activerecord.models.drawer_transaction.unrefund"),
      #        :is_refund => true, 
      #        :notes => I18n.t("views.notice.order_refund_dt",:id => self.order.id)
      #}
      #create_refund_transaction(self.total,:drop,opts) if not x.nil?
      #self.order.update_attribute(:total, self.order.total + t)
    else
      self.update_attribute(:refunded,true)
      self.update_attribute(:refunded_by, GlobalData.salor_user.id)
      self.update_attribute(:refunded_by_type, GlobalData.salor_user.class.to_s)
      self.update_attribute(:refund_payment_method, refund_payment_method)
      update_location_category_item(t * -1,q * -1)
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

      # $User.get_meta.vendor.open_cash_drawer unless $Register.salor_printer or self.order.refunded # open cash drawer only if not called from the Order.toggle_refund function # this is handled now by an onclick event in shared/_order_line_items_.html.erb
    end
  end
  def update_location_category_item(t,q)
    self.item.update_attribute(:quantity_sold, self.item.quantity_sold + q)
    self.item.update_attribute(:quantity, self.item.quantity + (-1 * q))
    if self.item.location then
      options = {
        :table => :locations, 
        :conditions => {:id => self.item.location_id}
      }
      self.item.location.update_attribute(:quantity_sold,salor_fetch_attr(:quantity_sold,options) + q) if self.quantity
      self.item.location.update_attribute(:cash_made, salor_fetch_attr(:cash_made,options) + t) if self.total
    end
    if self.item.category then
      options = {
        :table => :categories, 
        :conditions => {:id => self.item.category_id}
      }
      self.item.category.update_attribute(:quantity_sold, salor_fetch_attr(:quantity_sold,options) + q) if self.quantity
      self.item.category.update_attribute(:cash_made, salor_fetch_attr(:cash_made,options) + t) if self.total
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
    if (self.item.base_price == 0.0 or self.item.base_price == nil) and not self.item.must_change_price == true then
      self.item.update_attribute :base_price,p
    end
    if self.is_buyback == true and p > 0 then
      p = p * -1
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
    write_attribute(:quantity,q)
  end
  
	def set_item(item,qty=1)
    if self.order and self.order.paid == 1 then
      return false
    end
	  item.make_valid
		if item.item_type.behavior == 'gift_card' then
		  if item.activated and item.amount_remaining <= 0 then
		    GlobalErrors.append('system.errors.gift_card_empty',self)
		    self.is_valid = nil
		    return false
		  end
		end
		
		self.is_valid = true
		self.tax_profile_id = item.tax_profile_id
		self.item_type_id = item.item_type_id
		self.item_id = item.id
		self.weigh_compulsory = item.weigh_compulsory
		if item.default_buyback then
		  self.is_buyback = true
		end
		if self.weigh_compulsory then
		  self.quantity = 0
		else
		  self.quantity = qty
		end
		self.category_id = item.category_id
		self.location_id = item.location_id
		self.behavior = item.item_type.behavior
		self.tax_profile_amount = item.tax_profile.value
		self.amount_remaining = item.amount_remaining
		self.sku = item.sku
		self.activated = item.activated
		if self.quantity > item.quantity then
		  #GlobalErrors.append('system.errors.insufficient_quantity_on_item',self,{:sku => item.sku})
		end
		if item.is_gs1 then
		  p = get_gs1_price(GlobalData.params.sku, self.item)
		  if p.nil? then
		    GlobalErrors.append_fatal("system.errors.gs1_item_not_found",self,{:sku => GlobalData.params.sku})
		  end
		  if not self.item.price_by_qty then
		    self.price = p
		  else
		    self.quantity = p
		    self.price = self.item.base_price
		  end
		end
		if item.activated and item.amount_remaining >= 1 then
      self.price = item.amount_remaining
    else
      self.price = discover_price(item)
      oi = Action.run(self,:add_to_order)
      oi.total = oi.price * oi.quantity
      oi.calculate_tax(true)
      oi.save!
      return oi
    end
		self.save!
		return self
	end
	#
  def calculate_total(order_subtotal=0)
    # i.e. we should not be able to alter the total of an order item once the order is marked as paid.
    if self.order and self.order.paid == 1 then
      return self.total
    end
    if self.behavior == 'coupon' then
      self.update_attribute :total,self.price
      return self.price
    end

    #return self.total if self.order and self.order.paid == 1
    if self.order and self.order.buy_order or self.is_buyback then
      ttl = self.price * self.quantity
      if not ttl == self.total then
        self.update_attribute(:total,ttl)
      end
      return ttl
    end
    # Gift Card Processing
    if self.behavior == 'gift_card' then
      if self.item.activated then
        puts "Item is an activated gift_card"
        if self.amount_remaining <= 0 then
          puts "Amount remaining is 0"
          return 0
        end
        if self.price == 0 then
          self.price = self.amount_remaining
        end
        if self.price < 0 then
          self.price *= -1 # we do this so we can better set the price later
          # it will be reconverted to negative later on
        end
        if self.price > self.amount_remaining then
          self.price = self.amount_remaining
        end
        puts "Price: #{self.price} Subtotal: #{order_subtotal}"
        if self.price > order_subtotal then
          self.price = order_subtotal
        end
        if self.price > 0 then
          p = self.price * -1
        else
          p = self.price
        end
        self.update_attribute(:price, self.price) #if self.order and self.order.paid == 1
        self.update_attribute(:total,self.price)  #if self.order and self.order.paid == 1
        return p
      end
    end
        ttl = 0
    self.quantity = 0 if self.quantity.nil?
    if self.item.parts.any? and self.item.calculate_part_price then
      self.item.parts.each do |part|
        ttl += part.base_price * part.part_quantity
      end
        ttl = ttl * self.quantity
    else
      begin
        ttl = self.price * self.quantity
      rescue
        puts $!.inspect + " " + self.quantity.inspect + " " + self.price.inspect 
      end
      puts "OrderItem: #{self.price} * #{self.quantity} == #{ttl}"
    end
    
    if self.refunded and ttl > 0 then
      ttl = ttl * -1
    end
    puts "ttl at this point is: #{ttl}"
    # i.e. sometimes the order hasn't been saved yet..
    if self.order and self.order.coupon_for(self.item.sku) then
      cttl = 0
      self.order.coupon_for(self.item.sku).each do |c|
        cttl += c.coupon_total(ttl,self)
      end
      puts "OrderItem cttl: #{cttl} and ttl #{ttl}"
      ttl -= cttl
    end
    if self.rebate then
      ttl -= (ttl * (self.rebate / 100.0))
      puts "self.rebate: #{ttl}"
    end
    puts "ttl at this point is: #{ttl}"
    if self.discount_amount > 0 then
      ttl -= self.discount_amount
    end
    if not self.total == ttl and not self.total_is_locked then
      self.total = ttl.round(2)
      puts "In update, ttl is #{ttl} and self.total is #{self.total}"
      self.update_attribute(:total,ttl) #if self.order and not self.order.paid == 1
    end
    puts "Returning total of: #{self.total}"
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
    bp = (p *(100 / (100 + (100 * (self.tax_profile_amount/100))))).round(2);
    t = (p - bp).round(2)
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
    # puts "Coupon Total called ttl=#{ttl} type=#{self.item.coupon_type}"
    amnt = 0
    return 0 if ttl <= 0
    
    if self.item.coupon_type == 1 then #percent off self type
      puts "!!! coupon is percent"
      if self.quantity > oi.quantity then
        puts "!!! updating quantity"
        self.update_attribute :quantity,oi.quantity
        self.quantity = oi.quantity
      end
      q = self.quantity
      amnt = (oi.price * quantity) * (self.price / 100)
    elsif self.item.coupon_type == 2 then #fixed amount off
      # puts "Coupon is fixed"
      if self.price > ttl then
        #add_salor_error("system.errors.self_fixed_amount_greater_than_total",:sku => self.item.sku, :item => self.item.coupon_applies)
        amnt = ttl * self.quantity
        # puts "Setting to ttl " + ttl.to_s
      else
        amnt = self.item.base_price * self.quantity
        # puts "Setting to self.total " + self.item.base_price.to_s
      end
      self.update_attribute(:price,amnt)
      # puts "Fixed amnt = " + amnt.to_s
    elsif self.item.coupon_type == 3 then #buy 1 get 1 free
      if oi.quantity > 1 then
        if self.quantity > 1 then
          # this takes place when you have more than one b1g1 coupon and mored
          # than one target item.l
          q = self.quantity
          begin
            q -= 1  
          end until q == oi.quantity / 2 or q <= 1
          amnt = (oi.price * q)
        else
          amnt = (oi.price * self.quantity)
        end
      else
        add_salor_error("system.errors.coupon_not_enough_items")
      end
      self.update_attribute(:price,amnt)
    else
      # puts "couldn't figure out coupon type"
    end
    oi.update_attribute(:coupon_amount,amnt)
    oi.update_attribute(:coupon_applied, true)
    # puts "## Updating Attribute to #{amnt}"
    if amnt > 0 then
      oi.coupons << self
      oi.save
    end
    return amnt
  end
  def split
    
  end
  def discover_price(item)
    if self.order and self.order.buy_order or self.is_buyback then
      return item.buyback_price if self.order.buy_order
      return (item.buyback_price * -1)
    end
    if not item.behavior == 'normal' then
      if item.behavior == 'gift_card' and item.activated then
        return item.amount_remaining
      elsif item.behavior == 'coupon' then
        return item.base_price
      end
    end
    damount = 0
    if item.is_gs1 then
      p = self.price
    elsif item.parts.any? and item.calculate_part_price
      p = 0
      item.parts.each do |part|
        p += part.base_price * part.part_quantity
      end
    else
      p = item.base_price
    end
    pstart = p
    if not self.is_buyback and not OrderItem.get_discounts.nil? then
      OrderItem.get_discounts.each do |discount|
        if not (discount.item_sku == item.sku and discount.applies_to == 'Item') and
            not (discount.location_id == item.location_id and discount.applies_to == 'Location') and
            not (discount.category_id == item.category_id and discount.applies_to == 'Category') and
            not (discount.applies_to == 'Vendor' and discount.amount_type == 'percent') then
            # puts "this discount doesn't match"
            # puts "category_id is #{discount.category_id} and category_id is #{item.category_id}"
          next
        end
        if discount.amount_type == 'percent' then
          d = discount.amount / 100
          damount += (pstart * d)
          self.discounts << discount
        elsif discount.amount_type == 'fixed' then
          damount += discount.amount
          self.discounts << discount
        end
      end # Discount.scopied.where(conds)
    else
      # puts "Not Applying Discounts at all..."
    end
    #p -= damount
    self.update_attribute(:discount_applied,true) if self.discounts.any?
    self.update_attribute(:discount_amount,damount) if self.discounts.any?
    p = p.round(2)
    # puts "Is BuyBack: #{self.is_buyback}"
    return p
  end
  def to_json
    obj = {}
    if self.order and self.order.buy_order and self.is_buyback then
      self.update_attribute :is_buyback, false
    end
    if self.item then
      obj = {
        :name => self.item.name[0..20],
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
    # puts "My quantity is: #{self.quantity} and my #{self.behavior}"
    #
    # begin update the quantities of the item
    if the_item.ignore_qty == false and self.behavior == 'normal' then
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
      log_action "Checking Parts"
    	  if the_item.parts.any? then
        the_item.parts.each do |part|
          next if part.ignore_qty == true # i.e. we just ignore the qty
          part.quantity ||= 0
          if self.order and self.order.buy_order then
            part.update_attribute(:quantity, part.quantity + part.part_quantity)
          else
            part.update_attribute(:quantity, part.quantity - part.part_quantity)
          end
        end
      end
    # end Check Parts and update quantities
  end
  def update_quantity_sold
    the_item = self.item
    if the_item.category then
      the_item.category.update_attribute(:quantity_sold, the_item.category.quantity_sold + self.quantity)
    end
    if the_item.location then
      the_item.location.update_attribute(:quantity_sold,the_item.location.quantity_sold + self.quantity)
    end
  end
  def update_cash_made
    the_item = self.item
    if the_item.category then
      the_item.category.update_attribute(:cash_made, the_item.category.cash_made + self.total)
    end
    if the_item.location then
      the_item.location.update_attribute(:cash_made, the_item.location.cash_made + self.total)
    end
  end
end
