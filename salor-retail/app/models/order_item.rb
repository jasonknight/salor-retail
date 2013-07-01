# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class OrderItem < ActiveRecord::Base
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
  has_many :coupons, :class_name => 'OrderItem', :foreign_key => :coupon_id
  belongs_to :order_item,:foreign_key => :coupon_id
  has_many :histories, :as => :user
  has_one :drawer_transaction
  
  
  def get_tax_profile_letter
    return self.tax_profile.letter
  end
  
  def get_translated_name(locale)
    return self.item.get_translated_name(locale)
  end
  
  def get_category_name
    if self.category
      return self.category.name
    else
      return ""
    end
  end
  
  def get_location_name
    if self.item.location then
      return self.item.location.name
    else
      return ''
    end
  end
  
  def toggle_buyback=(x)
    self.is_buyback = ! self.is_buyback
    if self.is_buyback
      self.price = - self.item.buyback_price
    else
      self.price = self.item.base_price
    end
    self.calculate_totals
  end
  
  def create_refund_transaction(amount, type, user, opts)
    dt = DrawerTransaction.new(opts)
    dt[type] = true
    dt.amount = amount
    dt.drawer_id = user.get_drawer.id
    dt.drawer_amount = user.get_drawer.amount
    dt.order_id = self.order.id
    dt.order_item_id = self.id
    if dt.save then
      if type == :payout then
        user.get_drawer.update_attribute(:amount, user.get_drawer.amount - dt.amount)
      elsif type == :drop then
        @current_user.get_drawer.update_attribute(:amount, user.get_drawer.amount + dt.amount)
      end
    else
      raise dt.errors.full_messages.inspect
    end
  end
  
  def create_refund_payment_method(amount,refund_payment_method)
    PaymentMethod.create(:internal_type => (refund_payment_method + 'Refund'), 
                         :name => (refund_payment_method + 'Refund'), 
                         :amount => - amount, 
                         :order_id => self.order.id
                        )
  end
  

  def refund(refund_payment_method, user)
    return nil if self.refunded
    
    self.refunded = true
    self.refunded_by = user.id
    self.refunded_at = Time.now
    self.refund_payment_method = refund_payment_method
    self.save
    
    if refund_payment_method == 'InCash'
      dt = DrawerTransaction.new
      dt.vendor = user.vendor
      dt.company = user.company
      dt.user = user
      dt.is_refund = true
      dt.tag = 'OrderItemRefund'
      dt.notes = I18n.t("views.notice.order_refund_dt", :id => self.id)
      dt.order = self.order
      dt.order_item = self
      dt.drawer = user.get_drawer
      dt.amount = - self.subtotal
      dt.save
    end
  end

#   def update_location_category_item(t,q)
#     self.item.update_attribute(:quantity_sold, self.item.quantity_sold + q)
#     self.item.update_attribute(:quantity, self.item.quantity + (-1 * q))
#     loc = self.item.location
#     cat = self.item.category
#     if loc then
#       loc.update_attribute(:quantity_sold,loc.quantity_sold + q)
#       loc.update_attribute(:cash_made, loc.cash_made + t) 
#     end
#     if cat then
#       cat.update_attribute(:quantity_sold, cat.cash_made + q)
#       cat.update_attribute(:cash_made, cat.cash_made + t)
#     end
#   end
  
#   def toggle_lock=(x)
#     toggle_lock(x)
#   end

#   def toggle_lock(type)
#     return # we no longer support locking
#     if type == 'total' then
#       self.update_attribute(:total_is_locked,!self.total_is_locked)
#     elsif type == 'tax' then
#       self.update_attribute(:tax_is_locked,!self.tax_is_locked)
#     end
#   end
  
  
  def price=(p)
    if self.behavior == 'gift_card'
      p = self.string_to_float(p)
      i = self.item
      if i.activated.nil?
        i.base_price = p
        i.amount_remaining = p
        i.save
      end
    end
    write_attribute :price, p
  end
      
#   def price=(p)
#     if self.order and self.order.paid == 1 then
#       return
#     end
#     p = self.string_to_float(p)
#     if (self.item.base_price == 0.0 or self.item.base_price == nil) and (self.item.must_change_price == false or self.item.behavior == 'gift_card') then
#       self.item.update_attribute :base_price,p
#       if self.item.behavior == 'gift_card' then
#         self.item.update_attribute :amount_remaining, p
#       end
#     end
#     if self.is_buyback == true and p > 0 then
#       p = p * -1
#     end
#     if self.discounts.any? then
#       damount = 0
#       pstart = p * self.quantity
#       self.discounts.each do |discount|
#         if discount.amount_type == 'percent' then
#           d = discount.amount / 100
#           damount += (pstart * d)
#         elsif discount.amount_type == 'fixed' then
#           damount += discount.amount
#         end
#       end
#       write_attribute(:discount_amount, damount)
#       #self.calculate_total
#     end
#     write_attribute(:price,self.string_to_float(p)) #string_to_float SalorBase
#   end
  

#   def base_price=(p)
#     self.price = p
#   end
#   
#   def base_price
#     self.price
#   end
  
#   def total=(p)
#     if self.order and self.order.paid == 1 then
#       return
#     end
#     p = self.string_to_float(p)
#     if self.is_buyback == true and p > 0 then
#       p = p * -1
#     end
#     write_attribute(:total,p) 
#   end
  
#   def tax=(p)
#     if self.order and self.order.paid == 1 then
#       return
#     end
#     write_attribute(:tax,self.string_to_float(p)) 
#   end
  
#   def quantity=(q)
#     if self.order and self.order.paid == 1 then
#       return
#     end
#     if q.nil? or q.blank? then
#       q = 0
#     end
#     q = q.to_s.gsub(',','.')
#     q = q.to_f.round(3)
#     q = 0 if q < 0
#     if self.discounts.any? then
#       damount = 0
#       pstart = self.price * q
#       self.discounts.each do |discount|
#         if discount.amount_type == 'percent' then
#           d = discount.amount / 100
#           damount += (pstart * d)
#         elsif discount.amount_type == 'fixed' then
#           damount += discount.amount
#         end
#       end
#       write_attribute(:discount_amount, damount)
#       #self.calculate_total
#     end
#     write_attribute(:quantity,q)
#   end
  
  def set_attrs_from_item(item)
    return nil if self.order.paid
    self.vendor = item.vendor
    self.company = item.company
    
    self.item = item
    self.sku = item.sku
    self.price = item.base_price
    
    self.tax_profile = item.tax_profile
    self.tax = item.tax_profile.value # cache for faster processing
    
    self.item_type = item.item_type
    self.behavior = item.item_type.behavior # cache for faster processing
    
    self.is_buyback = item.default_buyback
    self.category = item.category
    self.location = item.location
    
    self.activated = item.activated
    self.amount_remaining = item.amount_remaining
    
    self.weigh_compulsory = item.weigh_compulsory
    self.quantity = self.weigh_compulsory ? 0 : 1
    self.user = self.order.user
  end
  
  
  def modify_price
    self.modify_price_for_giftcards
    self.modify_price_for_parts
    #self.modify_price_for_coupon
    self.save
  end
  
  
  def modify_price_for_giftcards
    if self.behavior == 'gift_card' and self.item.activated
      if self.amount_remaining > self.order.total.to_f
        self.price = - self.order.total
      else
        self.price = - self.amount_remaining
      end
      self.price = self.price.round(2)
    end
  end
  
  def modify_price_for_parts
    # TODO
  end
  

  
  def calculate_totals
    t = (self.price * self.quantity).round(2)    
    self.total = t.round(2)
    self.subtotal = self.total
    self.apply_coupon
    self.apply_discount
    self.apply_rebate
    self.calculate_tax
    self.save
  end
  
  def apply_coupon
    if self.behavior == 'coupon'
      item = self.item
      return if item.activated
      coitem = self.order.order_items.visible.find_by_sku(item.coupon_applies)
      if coitem
        ctype = self.item.coupon_type
        if ctype == 1
          # percent rebate
          coitem.coupon_amount = (coitem.subtotal * item.amount_remaining / 100.0).round(2)
        elsif ctype == 2
          # fixed amount
          coitem.coupon_amount = coitem.subtotal - self.amount_remaining
        elsif ctype == 3
          # buy 1 get 1
          if coitem.quantity >= 2
            coitem.coupon_amount = (coitem.subtotal / 2).round(2)
          end
        end
        coitem.subtotal -= coitem.coupon_amount
        coitem.save
        item.activated = true
        item.save
      end
    end
  end
  
  def apply_rebate
    if self.rebate
      self.rebate_amount = (self.subtotal * self.rebate / 100.0).round(2)
      self.subtotal -= self.rebate_amount
    end
  end
  
  def apply_discount
    # Vendor
    discount = self.vendor.discounts.visible.where("start_date < '#{ Time.now }' AND end_date > '#{ Time.now }'").where(:applies_to => "Vendor").first
    
    # Category
    discount ||= self.vendor.discounts.visible.where("start_date < '#{ Time.now }' AND end_date > '#{ Time.now }'").where(:applies_to => "Category", :category_id => self.category ).first
    
    # Location
    discount ||= self.vendor.discounts.visible.where("start_date < '#{ Time.now }' AND end_date > '#{ Time.now }'").where(:applies_to => "Location", :location_id => self.location ).first
    
    # Item
    discount ||= self.vendor.discounts.visible.where("start_date < '#{ Time.now }' AND end_date > '#{ Time.now }'").where(:applies_to => "Item", :item_sku => self.sku ).first
    
    if discount
      self.discount = discount.amount
      self.discount_amount = (self.subtotal * discount.amount / 100.0).round(2)
      self.subtotal -= self.discount_amount
    end
  end

  
  def calculate_tax
    if self.vendor.calculate_tax == true
      t = self.subtotal * self.tax / 100.0
    else
      t = self.subtotal / ( 1 + self.tax / 100.0 )
    end
    self.tax_amount = t.round(2)
  end
  
  
  def quantity=(q)
    q = self.string_to_float(q)
    return if ( self.behavior == 'gift_card' or self.behavior == 'coupon' ) and q != 1
    write_attribute :quantity, q
  end
  
  
  def hide(by)
    puts "XXXX"
  end
  
  
  
  
#   def calculate_total_with_rebate(rebate = nil)
#     # This calculates OrderItem total for ITEM rebate
#     if rebate.nil? then
#       rebate = self.rebate
#     else
#       self.rebate = rebate
#     end
#     rebate = 0 if rebate.nil?
#     self.total = ((self.price * self.quantity) - (self.price * self.quantity * (rebate / 100.0))).round(2)
#     return self.total
#   end
# 
#   def calculate_rebate_amount
#     self.rebate_amount = (self.price * self.quantity * (self.rebate / 100.0)).round(2)
#   end
# 
#   def calculate_oi_order_rebate
#     # This calculates ORDER rebate for % only for a given OrderItem
# 	  amnt = 0.0
# 	  self.total = 0 if self.total.nil?
#     if self.order.rebate_type == 'percent' then
#       amnt = self.total * (self.order.rebate / 100.0)
#     end
#     return amnt    
#   end
#   #
#   def gross
#     return self.total
#   end
#   #
  
  
#   def calculate_tax(no_update = false)
#     return 0 if self.tax_free == true or (self.order and self.order.tax_free == true)
#     return 0 if self.refunded
#     if self.activated and self.behavior == 'gift_card' then
#       self.update_attribute(:tax,0) if self.tax != 0
#       return 0
#     end
#     if self.behavior == 'coupon' then
#       self.update_attribute(:tax,0) if self.tax != 0
#       return 0 
#     end
#     self.tax = 0 if self.tax.nil?
#     return self.tax if self.tax_is_locked
#     return 0 if not self.tax_profile_amount
#     p = self.total
#     if $Conf and not $Conf.calculate_tax then
#       net_price = (p *(100 / (100 + (100 * (self.tax_profile_amount/100))))).round(2);
#       t = (p - net_price).round(2)
#     else
#       t = p * (self.tax_profile_amount/100.00)
#     end
#     if not t == self.tax and not self.tax_is_locked then #i.e. we get the total from above 
#       # in order to not charge for buy 1 get one frees
#       self.tax = t
#       self.update_attribute(:tax,t) unless no_update == true
#     end
#     if self.tax.nil? then
#       self.tax = t
#     end
#     return self.tax
#   end

  
#   def coupon_total(ttl,oi)
#     # #ActiveRecord::Base.logger.info "Coupon Total called ttl=#{ttl} type=#{self.item.coupon_type}"
#     amnt = 0
#     return 0 if ttl <= 0
#     if self.quantity > oi.quantity then
#       self.update_attribute(:quantity,oi.quantity)
#       self.quantity = oi.quantity
#     end
# 
#     if self.item.coupon_type == 1 then #percent off self type
#       q = self.quantity
#       amnt = (oi.price * quantity) * (self.price / 100)
#     elsif self.item.coupon_type == 2 then #fixed amount off
#       # #ActiveRecord::Base.logger.info "Coupon is fixed"
#       if self.price > ttl then
#         #add_salor_error("system.errors.self_fixed_amount_greater_than_total",:sku => self.item.sku, :item => self.item.coupon_applies)
#         amnt = ttl * self.quantity
#         # #ActiveRecord::Base.logger.info "Setting to ttl " + ttl.to_s
#       else
#         amnt = self.item.base_price * self.quantity
#         # #ActiveRecord::Base.logger.info "Setting to self.total " + self.item.base_price.to_s
#       end
#       self.update_attribute(:total,amnt)
#       # #ActiveRecord::Base.logger.info "Fixed amnt = " + amnt.to_s
#     elsif self.item.coupon_type == 3 then #buy 1 get 1 free
#       if oi.quantity > 1 then
#         if self.quantity > 1 then
#           # this takes place when you have more than one b1g1 coupon and mored
#           # than one target item.l
#           q = self.quantity
#           q = (oi.quantity / 2).to_i
#           amnt = (oi.price * q)
#         else
#           amnt = (oi.price * self.quantity)
#         end
#       else
#         add_salor_error("system.errors.coupon_not_enough_items")
#       end
#       self.update_attribute(:total,amnt)
#     else
#       # #ActiveRecord::Base.logger.info "couldn't figure out coupon type"
#     end
#     oi.update_attribute(:coupon_amount,amnt)
#     oi.update_attribute(:coupon_applied, true)
#     # #ActiveRecord::Base.logger.info "## Updating Attribute to #{amnt}"
#     if amnt > 0 then
#       oi.coupons << self
#       oi.save
#     end
#     return amnt
#   end


#   def discover_price
#     if self.order.buy_order or self.is_buyback
#       self.price = - item.buyback_price
#       self.save
#       return
#     end
# 
#     if self.item.behavior == 'gift_card' and self.item.activated then
#       self.price = self.item.amount_remaining
#       self.save
#       return
#     elsif self.item.behavior == 'coupon' then
#       self.price = self.item.base_price
#       self.save
#       return
#     end
# 
#     self.price = self.item.base_price
#     
#     discounts = self.vendor.get_current_discounts
#     discounts.each do |d|
#       if (d.item_sku == item.sku and d.applies_to == 'Item') or
#           (d.location_id == item.location_id and d.applies_to == 'Location') or
#           (d.category_id == item.category_id and d.applies_to == 'Category') or
#           (d.applies_to == 'Vendor' and d.amount_type == 'percent')
# 
#         self.discounts << d
# 
#         if d.amount_type == 'percent'
#           self.discount_amount = self.price * d.amount / 100
#         elsif d.amount_type == 'fixed'
#           self.discount_amount = d.amount
#         end
#         self.price -= self.discount_amount
#         self.discounts << d
#         self.discount_applied = true
#         self.save
#       end
#     end
#   end

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
        :subtotal => self.subtotal.round(2),
        :id => self.id,
        :behavior => self.behavior,
        :discount_amount => self.discount_amount.round(2) * -1,
        :rebate => self.rebate.nil? ? 0 : self.rebate,
        :is_buyback => self.is_buyback,
        :weigh_compulsory => self.item.weigh_compulsory,
        :must_change_price => self.item.must_change_price,
        :weight_metric => self.item.weight_metric,
        :tax => self.tax,
        :action_applies => self.action_applies
      }
    end
    if self.behavior == 'gift_card' and self.activated then
      obj[:price] = obj[:price] * -1
    end
    return obj.to_json
  end
  
  def update_item_quantities
    items = []
    items << self.item
    items << self.item.parts
    items.flatten!
    
    items.each do |i|
      if i.ignore_qty.nil? and i.behavior == 'normal' and self.order.is_proforma.nil?
        if self.is_buyback
          i.quantity += self.quantity
          i.quantity_buyback += self.quantity
        else
          i.quantity -= self.quantity
          i.quantity_sold += self.quantity
        end
      end
      i.save
    end
  end
  
#   def recover_item
#     i = Item.find_by_sku(self.sku)
#     if i then
#       self.item = i
#       self.save
#       return
#     else
#       i = Item.get_by_code(self.sku)
#       i.item_type_id = self.item_type_id
#       i.base_price = self.price
#       i.save
#       self.item = i
#       self.save
#     end
#   end
  
  def debug
    if self.behavior == 'gift_card'
      puts "GIFT CARD"
      puts "---------"
      puts "self.price              = #{ self.price.inspect }"
      puts "self.total              = #{ self.total.inspect }"
      puts "self.activated          = #{ self.activated.inspect }"
      puts "self.amount_remaining   = #{ self.amount_remaining.inspect }"
      puts "self.item.base_price         = #{ self.item.base_price.inspect }"
      puts "self.item.activated          = #{ self.item.activated.inspect }"
      puts "self.item.amount_remaining   = #{ self.item.amount_remaining.inspect }"
    end
  end

end
