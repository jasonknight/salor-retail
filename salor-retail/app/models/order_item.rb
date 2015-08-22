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
  has_one :drawer_transaction # set for refunds only
  has_one :refund_payment_method_item, :class_name => 'PaymentMethodItem', :foreign_key => :order_item_id


  monetize :total_cents, :allow_nil => true
  monetize :price_cents, :allow_nil => true
  monetize :tax_amount_cents, :allow_nil => true
  monetize :coupon_amount_cents, :allow_nil => true
  monetize :gift_card_amount_cents, :allow_nil => true
  monetize :discount_amount_cents, :allow_nil => true
  monetize :rebate_amount_cents, :allow_nil => true
  
  validates_presence_of :user_id
  validates_presence_of :drawer_id
  validates_presence_of :company_id
  validates_presence_of :vendor_id
  validates_presence_of :user_id
  validates_presence_of :order_id
  validates_presence_of :quantity
  validates_presence_of :tax_profile_id
  validates_presence_of :item_type_id
  validates_presence_of :behavior
  validates_presence_of :sku
  

  
  def is_normal?
    return (self.is_buyback != true and self.behavior == 'normal')
  end
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

  def base_price
    return self.price
  end
  
  def base_price=(p)
    if p.class == String
      # a string is sent from Vendor.edit_field_on_child
      p = Money.new(self.string_to_float(p, :locale => self.vendor.region) * 100.0, self.currency)
    elsif p.class == Float
      # not sure which parts of the code send a Float, but we leave it here for now
      p = Money.new(p * 100.0, self.currency)
    end
    self.price = p
  end
  
  def name=(name)
    # this does nothing. it is here for setting name on the detailed JS item configuraiton menu, because this sets name for Item and OrderItem.
  end
  
  def tax=(value)
    tp = TaxProfile.find_by_percentage(value, self.vendor)
    if tp.nil?
      msg = "A TaxProfile with value #{ value } has to be created before you can assign this value"
      log_action msg
      #raise msg
    else
      write_attribute :tax_profile_id, tp.id
      write_attribute :tax, tp.value
    end
  end
  
  
  
  def tax_profile_id=(id)
    tp = self.vendor.tax_profiles.visible.find_by_id(id)
    if tp.nil?
      msg = "Could not find TaxProfile with id #{ id } for self's vendor."
      log_action msg
      raise msg
    else
      write_attribute :tax_profile_id, id
      write_attribute :tax, tp.value
    end
  end

  def price=(p)
    if p.class == String
      # a string is sent from Vendor.edit_field_on_child
      p = Money.new(self.string_to_float(p, :locale => self.vendor.region) * 100.0, self.currency)
    elsif p.class == Float or p.class == Fixnum
      # not sure which parts of the code send a Float, but we leave it here for now
      p = Money.new(p * 100.0, self.currency)
    end
    
    # this is needed for dynamically created gift cards on the POS screen.
    if self.behavior == 'gift_card'
      i = self.item
      if i.activated.nil?
        i.price = p
        i.gift_card_amount = p
        i.save
      end
    end
    
    # don't allow negative inputs
    if p.fractional < 0 and (not self.is_buyback and self.item.item_type.behavior != "gift_card")
      $MESSAGES[:prompts] << I18n.t("system.errors.cannot_set_negative_price")
      p *= -1
      return
    end
    
    # make price negative when it is a buyback OrderItem
    if self.is_buyback
      p = - p.abs
    end
    
    # update item only when price is 0
    i = self.item
    if i.weigh_compulsory != true and i.must_change_price != true and i.default_buyback != true and i.price.zero?
      i.price = p
      i.save!
    end
    write_attribute :price_cents, p.fractional
  end
  
  # this method is just for documentation purposes: that total always includes tax. it is the physical money that has to be collected from the customer.
  def gross
    # log_action "gross #{ self.total_cents.inspect }"
    return self.total
  end
  
  def net
    return self.total - self.tax_amount
  end

  
  def set_attrs_from_item(item)
    self.vendor       = item.vendor
    self.company      = item.company
    self.currency     = item.currency
    self.item         = item
    self.sku          = item.sku
    self.price        = item.price
    self.tax          = item.tax_profile.value
    #self.tax_profile  = item.tax_profile # this association is made in self.tax=()
    self.item_type    = item.item_type
    self.behavior     = item.item_type.behavior # cache for faster processing
    self.is_buyback   = item.default_buyback
    self.category     = item.category
    self.location     = item.location
    self.activated    = item.activated
    self.no_inc       = item.is_gs1
    self.gift_card_amount = item.gift_card_amount
    self.weigh_compulsory = item.weigh_compulsory
    self.quantity     = self.weigh_compulsory ? 0 : 1
    self.no_inc       = self.weigh_compulsory
    self.calculate_part_price = item.calculate_part_price # cache for faster processing
    self.user         = self.order.user
  end
  
  # This method is only called on add to order
  # otherwise calculate_totals is called
  def modify_price
    log_action "Modifying price for actions"
    redraw_all_order_items = self.modify_price_for_actions
    log_action "Modifying price for gs1"
    self.modify_price_for_gs1
    if self.is_buyback
      log_action "modify_price_for_buyback"
      self.modify_price_for_buyback 
    end
    self.modify_price_for_parts
    if self.behavior == 'gift_card'
      log_action "modify_price_for_giftcards"
      self.modify_price_for_giftcards 
    end
    self.save!
    return redraw_all_order_items
  end
  
  def modify_price_for_actions
    log_action "modify_price_for_actions"
    redraw_all_order_items = Action.run(self.vendor, self, :add_to_order)
    self.reload
    return redraw_all_order_items
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
        #self.price = self.item.base_price * self.quantity # this is the case anyway
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
      if self.item.gift_card_amount > self.order.total
        self.price = - self.order.total
      else
        self.price = - self.gift_card_amount
      end
    end
  end
  
  def modify_price_for_parts
    if self.calculate_part_price
      self.price = self.item.parts.visible.collect{ |p| p.base_price * p.part_quantity }.sum
    end
  end
  
  def calculate_totals
    if self.refunded or self.behavior == 'coupon'
      # coupons do have a total of 0, because they are not sold. they act on a matching OrderItem instead.
      self.total = 0
    else
      # at this point, total is net for the USA tax system and gross for the Europe tax system.
      self.total = self.price * self.quantity
    end
    
    self.adapt_gross

    # Now, the total can be subject to price reductions. the following apply_ methods handle this and modify self.total
    self.apply_discount
    self.apply_rebate
    self.apply_coupon
    
    # this method calculates taxes and transforms "total" to always include tax
    self.calculate_tax
    self.save!
  end
  
  # this method calculates taxes and transforms "total" to always include tax
  def calculate_tax
    if self.vendor.net_prices
      # this is for the US tax system. At this point, total is still net.
      self.tax_amount = self.total * self.tax / 100.0
      # here, total becomes gross
      self.total += tax_amount
    else
      # this is for the Europe tax system. self.total is already gross, so we don't have to modify it here.
      self.tax_amount = self.total * ( 1 - 1 / ( 1 + self.tax / 100.0 ) )
    end
  end
  
  # This is only for the European tax system. Item.price is already gross and implicitly includes a tax amount for the specific TaxProfile set on Item, However, the user can change the TaxProfile from the POS screen. If that happens, we have to find the implied net part of self.total, and re-calculate self.total according to the set tax.
  def adapt_gross
    return if self.vendor.net_prices || self.tax == self.item.tax_profile.value
    
    net_cents = self.total_cents / ( 1.0 + ( self.item.tax_profile.value / 100.0 ) )
    self.total_cents = (net_cents * ( 1.0 + ( self.tax / 100.0 ) )).round(2)
  end
  
  # coupons have to be added on the POS screen AFTER the matching product
  # coupons do not have a price by themselves, they just reduce the total of the matching OrderItem. Note that this method does not act on self, but to the matching OrderItem.
  def apply_coupon
    if self.behavior == 'coupon'
      item = self.item
      
      # coitem is the OrderItem to which the coupon acts upon
      coitem = self.order.order_items.visible.find_by_sku(item.coupon_applies)
      log_action "apply_coupon: coitem was not found" and return if coitem.nil?

      unless coitem.coupon_amount.zero? then
        log_action "apply_coupon: This item is a coupon, but a coupon_amount has already been set"
        return
      end
      
      log_action "apply_coupon: Starting to apply coupons. total before is #{ coitem.total_cents }"
      
      ctype = self.item.coupon_type
      if ctype == 1
        # percent rebate
        factor = self.price_cents / 100.0 / 100.0
        if self.vendor.net_prices
          coitem.coupon_amount_cents = coitem.net.fractional * factor
        else
          coitem.coupon_amount_cents = coitem.gross.fractional * factor
        end
        log_action "apply_coupon: Applying Percent rebate coupon: price_cents is #{ self.price_cents }, factor is #{ factor }, coupon_amount_cents is #{ coitem.coupon_amount_cents }"
      elsif ctype == 2
        # fixed amount
        coitem.coupon_amount_cents = self.price_cents
        log_action "apply_coupon: Applying Fixed amount coupon: coupon_amount_cents is #{ coitem.coupon_amount_cents }"
      elsif ctype == 3
        # buy x get y free
        log_action "apply_coupon: Applying B1G1"
        x = 2
        y = 1
        if coitem.quantity >= x
          if self.vendor.net_prices
            coitem.coupon_amount_cents = y * coitem.net.fractional / coitem.quantity
          else
            coitem.coupon_amount_cents = y * coitem.gross.fractional / coitem.quantity
          end
          log_action "apply_coupon: Applying B1G1 coupon: coupon_amount_cents is #{ coitem.coupon_amount_cents }"
        end
      end
      if self.vendor.net_prices
        coitem.total = coitem.net - coitem.coupon_amount
      else
        # log_action "XXXXXXXXX #{ coitem.gross.inspect } #{ coitem.coupon_amount.inspect  }"
        coitem.total = coitem.gross - coitem.coupon_amount
      end
      log_action "apply_coupon: OrderItem Total after coupon applied is: #{coitem.total_cents} and coupon_amount is #{coitem.coupon_amount_cents}"
      coitem.calculate_tax
      coitem.save!
    else
      self.total -= self.coupon_amount
    end
  end
  
  def apply_rebate
    if self.rebate
      log_action "Applying rebate to #{ self.id }"
      self.rebate_amount_cents = (self.total_cents * (self.rebate / 100.0))
      log_action "rebate_amount is #{self.rebate_amount_cents}"
      self.total_cents -= self.rebate_amount_cents
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
      log_action "Applying discount"
      self.discount = discount.amount
      self.discount_amount_cents = (self.total_cents * discount.amount / 100.0)
      self.total_cents -= self.discount_amount_cents
      self.discounts << discount
    end
  end

  def quantity=(q)
    q = self.string_to_float(q, :locale => self.vendor.region)
    if ( self.behavior == 'gift_card' or self.behavior == 'coupon' ) and q != 1
      log_action "Cannot have more than 1 coupon or gift card"
      return
    end

    write_attribute :quantity, q
  end
  
  
  def hide(by)
    self.hidden = true
    self.hidden_by = by.id
    self.hidden_at = Time.now
    if not self.save then
      log_action self.errors.full_messages.to_sentence
      raise "Could Not Hide Item"
    end

    if self.behavior == 'coupon'
      item = self.item
      raise "could not find Item for OrderItem #{ self.id }" if item.nil?
      coitem = self.order.order_items.visible.find_by_sku(item.coupon_applies)
      log_action "WARNING: Could not find a visible OrderItem #{ item.coupon_applies.inspect }. It probably was deleted from the POS screen before this coupon was deleted." if coitem.nil?
      coitem.coupon_amount = Money.new(0, self.currency)
      coitem.calculate_totals
    end
    self.order.calculate_totals
  end

  def to_json
    obj = {}
    if self.item then
      obj = {
        :name => self.get_translated_name(I18n.locale)[0..20],
        :category_id => self.category_id,
        :sku => self.item.sku,
        :item_id => self.item_id,
        :activated => self.item.activated,
        :gift_card_amount => self.item.gift_card_amount.to_f,
        :coupon_type => self.item.coupon_type,
        :quantity => self.quantity, #quantity_string,
        :price => self.price.to_f,
        :discount_amount => self.discount_amount.to_f,
        :rebate_amount => self.rebate_amount.to_f,
        :coupon_amount => self.coupon_amount.to_f,
        :total => self.total.to_f,
        :id => self.id,
        :behavior => self.behavior,
        :item_type_id => self.item_type_id,
        :rebate => self.rebate.to_f,
        :is_buyback => self.is_buyback,
        :weigh_compulsory => self.item.weigh_compulsory,
        :must_change_price => self.item.must_change_price,
        :weight_metric => self.item.weight_metric,
        :tax => self.tax,
        :tax_profile_id => self.tax_profile_id,
        :action_applied => self.action_applied
      }
    end
    return obj.to_json
  end
  
  def check
    tests = []
    
    # ---
    if self.refunded
      should = 0
      actual = self.total_cents
      pass = should == actual
      msg = "total_cents for refunded should be 0"
      type = :orderItemTotalZeroRefunded
      tests << {:model=>"OrderItem", :id=>self.id, :t=>type, :m=>msg, :s=>should, :a=>actual} if pass == false
    end
      
    # ---
    if self.refunded != true
      price_reductions = coupon_amount_cents.to_i + discount_amount_cents.to_i + rebate_amount_cents.to_i
      
      if self.vendor.net_prices
        should = Money.new((self.quantity * self.price_cents) - price_reductions + self.tax_amount_cents, self.vendor.currency)
        actual = self.total
        pass = should == actual
        msg = "total must be (price * quantity) - price reductions + tax_amount"
        type = :orderItemTotalCorrectNet
        tests << {:model=>"OrderItem", :id=>self.id, :t=>type, :m=>msg, :s=>should.fractional, :a=>actual.fractional} if pass == false
        
      else
        should = Money.new((self.quantity * self.price_cents) - price_reductions, self.vendor.currency)
        actual = self.total
        pass = should == actual
        msg = "total must be (price * quantity) - price reductions"
        type = :orderItemTotalCorrect
        tests << {:model=>"OrderItem", :id=>self.id, :t=>type, :m=>msg, :s=>should.fractional, :a=>actual.fractional} if pass == false
      end
    end
      
    # ---
    if self.behavior == 'gift_card' and self.activated == true
      should = - self.total_cents.abs
      actual = self.total_cents
      pass = should == actual
      msg = "price of activated gift card should be negative"
      type = :orderItemGiftcardPriceNegative
      tests << {:model=>"OrderItem", :id=>self.id, :t=>type, :m=>msg, :s=>should, :a=>actual} if pass == false
    end
    
    # ---
    if self.behavior == 'gift_card' and self.activated == nil
      should = self.total_cents.abs
      actual = self.total_cents
      pass = should == actual
      msg = "price of activated gift card should be positive"
      type = :orderItemGiftcardPricePositive
      tests << {:model=>"OrderItem", :id=>self.id, :t=>type, :m=>msg, :s=>should, :a=>actual} if pass == false
    end
    
    # ---
    if self.behavior == 'gift_card'
      should = 0
      actual = self.tax_amount_cents
      pass = should == actual
      msg = "tax of gift card should be zero"
      type = :orderItemGiftcardTaxZero
      tests << {:model=>"OrderItem", :id=>self.id, :t=>type, :m=>msg, :s=>should, :a=>actual} if pass == false
    end
    
    # ---
    if self.is_buyback == true
      should = - self.total_cents.abs
      actual = self.total_cents
      pass = should == actual
      msg = "buyback items must have a negative price"
      type = :orderItemBuybackPriceNegative
      tests << {:model=>"OrderItem", :id=>self.id, :t=>type, :m=>msg, :s=>should, :a=>actual} if pass == false
    end
    
    if self.is_buyback == nil and self.behavior != "gift_card"
      should = self.total_cents.abs
      actual = self.total_cents
      pass = should == actual
      msg = "non-buyback items must have a positive price"
      type = :orderItemNonBuybackPricePositive
      tests << {:model=>"OrderItem", :id=>self.id, :t=>type, :m=>msg, :s=>should, :a=>actual} if pass == false
    end
    
    # ---
    if self.vendor.net_prices
      price_reductions = coupon_amount_cents.to_i + discount_amount_cents.to_i + rebate_amount_cents.to_i
      subtotal = (self.quantity * self.price_cents) - price_reductions
      
      should = Money.new(subtotal * self.tax / 100.0, self.currency)
      actual = self.tax_amount
      pass = should == actual
      msg = "tax must be correct"
      type = :orderItemTaxCorrectNet
      tests << {:model=>"OrderItem", :id=>self.id, :t=>type, :m=>msg, :s=>should.fractional, :a=>actual.fractional} if pass == false
      
#       pass = (should.fractional - actual.fractional).abs != 1
#       msg = "1 cent rounding error"
#       type = :orderItemTaxRoundingNet
#       tests << {:model=>"OrderItem", :id=>self.id, :t=>type, :m=>msg, :s=>should, :a=>actual} if pass == false
      
    else
      should = Money.new(self.total_cents * ( 1 - 1 / ( 1 + self.tax / 100.0)), self.currency)
      actual = self.tax_amount
      pass = should == actual
      msg = "tax must be correct"
      type = :orderItemTaxCorrect
      tests << {:model=>"OrderItem", :id=>self.id, :t=>type, :m=>msg, :s=>should.fractional, :a=>actual.fractional} if pass == false
      
      pass = (should.fractional - actual.fractional).abs != 1
      msg = "1 cent rounding error"
      type = :orderItemTaxRounding
      tests << {:model=>"OrderItem", :id=>self.id, :t=>type, :m=>msg, :s=>should.fractional, :a=>actual.fractional} if pass == false
    end
    
    # ---
    if self.behavior == 'gift_card'
      should = 1
      actual = self.quantity
      pass = should == actual
      msg = "gift card should have quantity of 1"
      type = :orderItemGiftcardQuantity
      tests << {:model=>"OrderItem", :id=>self.id, :t=>type, :m=>msg, :s=>should, :a=>actual} if pass == false
    end
    
    # ---
    if self.behavior == 'coupon'
      should = 1
      actual = self.quantity
      pass = should == actual
      msg = "coupon should have quantity of 1"
      type = :orderItemCouponQuantity
      tests << {:model=>"OrderItem", :id=>self.id, :t=>type, :m=>msg, :s=>should, :a=>actual} if pass == false
    end
    
    return tests
  end

end
