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
  belongs_to :drawer
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
    self.modify_price_for_buyback
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
  

  def refund(pmid, user)
    return nil if self.refunded
    
    drawer = user.get_drawer
    refund_payment_method = self.vendor.payment_methods.visible.find_by_id(pmid)
    
    pmi = PaymentMethodItem.new
    pmi.vendor = self.vendor
    pmi.company = self.company
    pmi.order = self.order
    pmi.user = user
    pmi.drawer = drawer
    pmi.amount = - self.subtotal
    pmi.payment_method_id = refund_payment_method
    pmi.cash = refund_payment_method.cash
    pmi.refund = true
    pmi.save
    
    if refund_payment_method.cash == true
      dt = DrawerTransaction.new
      dt.vendor = user.vendor
      dt.company = user.company
      dt.user = user
      dt.refund = true
      dt.tag = 'OrderItemRefund'
      dt.notes = I18n.t("views.notice.order_refund_dt", :id => self.id)
      dt.order = self.order
      dt.order_item_id = self.id
      dt.drawer = drawer
      dt.drawer_amount = drawer.amount
      dt.amount = - self.subtotal
      dt.save
      drawer.amount -= self.subtotal
      drawer.save
    end
    
    self.refunded = true
    self.refunded_by = user.id
    self.refunded_at = Time.now
    self.refund_payment_method_item_id = pmid.to_i
    self.calculate_totals
    
    order = self.order
    order.calculate_totals
  end
  
  def split
    order = self.order
    order.paid = nil
    order.save
    noi = self.dup
    self.quantity -= 1
    self.calculate_totals
    noi.quantity = 1
    noi.calculate_totals
    order.calculate_totals
    order.paid = true
    order.save
  end


  
  def price=(p)
    p = self.string_to_float(p)
    if self.behavior == 'gift_card'
      i = self.item
      if i.activated.nil?
        i.base_price = p
        i.amount_remaining = p
        i.save
      end
    end
    if self.is_buyback
      p = - p.abs
    end
    write_attribute :price, p
  end
      

  
  def set_attrs_from_item(item)
    return nil if self.order.paid
    self.vendor = item.vendor
    self.company = item.company
    self.item = item
    self.price = item.base_price
    self.tax_profile = item.tax_profile
    self.tax = item.tax_profile.value # cache for faster processing
    self.item_type = item.item_type
    self.behavior = item.item_type.behavior # cache for faster processing
    self.is_buyback = item.default_buyback
    self.category = item.category
    self.location = item.location
    self.activated = item.activated
    self.no_inc = item.is_gs1
    self.amount_remaining = item.amount_remaining
    self.weigh_compulsory = item.weigh_compulsory
    self.quantity = self.weigh_compulsory ? 0 : 1
    self.calculate_part_price = item.calculate_part_price # cache for faster processing
    self.user = self.order.user
  end
  
  
  def modify_price
    self.modify_price_for_buyback
    self.modify_price_for_actions
    self.modify_price_for_parts
    self.modify_price_for_giftcards
    self.modify_price_for_gs1
    self.save
  end
  
  def modify_price_for_actions
    Action.run(self, :add_to_order)
  end
  
  def modify_price_for_gs1
    if self.item.is_gs1
      m = self.vendor.gs1_regexp.match(self.sku)     
      return unless m and m[2]
      value = m[2]
      m = self.item.gs1_regexp.match(value)
      return unless m and m[2]
      value = "#{m[1]}.#{m[2]}".to_f
      if self.item.price_by_qty
        self.quantity = value
        self.price = self.item.base_price * self.quantity
      else
        self.price = value
      end
    end
  end
  
  def modify_price_for_buyback
    if self.is_buyback
      self.price = - self.item.buyback_price
    else
      self.price = self.item.base_price
    end
  end
  
  def modify_price_for_giftcards
    if self.behavior == 'gift_card' and self.item.activated
      if self.item.amount_remaining > self.order.total.to_f
        self.price = - self.order.total.to_f
      else
        self.price = - self.amount_remaining
      end
      self.price = self.price.round(2)
    end
  end
  
  def modify_price_for_parts
    if self.calculate_part_price
      self.price = self.item.parts.visible.collect{ |p| p.base_price * p.part_quantity }.sum
    end
  end
  
  
  

  
  def calculate_totals
    if self.refunded
      t = 0
    else
      t = (self.price * self.quantity).round(2)
    end
    self.total = t.round(2)
    self.subtotal = self.total
    self.apply_coupon
    self.apply_discount
    self.apply_rebate
    self.calculate_tax
    self.save
  end
  
  # coupons have to be added after the matching product
  # coupons do not have a price by themselves, they just reduce the quantity of the matching OrderItem
  def apply_coupon
    if self.behavior == 'coupon'
      item = self.item
      coitem = self.order.order_items.visible.find_by_sku(item.coupon_applies)
      return unless coitem.coupon_amount.nil?
      if coitem
        ctype = self.item.coupon_type
        if ctype == 1
          # percent rebate
          coitem.coupon_amount = (coitem.subtotal * item.amount_remaining / 100.0).round(2)
        elsif ctype == 2
          # fixed amount
          coitem.coupon_amount = self.amount_remaining
        elsif ctype == 3
          puts 'xx'
          # buy x get y free
          x = 2
          y = 1
          if coitem.quantity >= x
            coitem.coupon_amount = coitem.subtotal / coitem.quantity * y
          end
        end
        coitem.subtotal -= coitem.coupon_amount
        coitem.save
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
    if self.vendor.net_prices
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
    self.hidden = true
    self.hidden_by = by
    self.hidden_at = Time.now
    self.save
    if self.behavior == 'coupon'
      coitem = self.order.order_items.visible.find_by_sku(item.coupon_applies)
      coitem.coupon_amount = nil
      coitem.calculate_totals
    end
    self.order.calculate_totals
  end
  
  
  
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
        :action_applied => self.item.actions.visible.any?
      }
    end
    return obj.to_json
  end

end
