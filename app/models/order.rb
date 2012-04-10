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
class Order < ActiveRecord::Base
 # {START}
	include SalorScope
  include SalorError
  include SalorBase
  include SalorModel
	has_many :order_items
	has_many :payment_methods
	has_many :paylife_structs
  belongs_to :user
  belongs_to :employee
  belongs_to :customer
  belongs_to :vendor
  belongs_to :cash_register
  belongs_to :cash_register_daily
  has_and_belongs_to_many :discounts
  scope :last_seven_days, lambda { where(:created_at => 7.days.ago.utc...Time.now.utc) }
  # These two associations are here for eager loading to speed things up
  has_many :coupons, :class_name => "OrderItem", :conditions => "behavior = 'coupon' and hidden != 1" 
  has_many :gift_cards, :class_name => "OrderItem", :conditions => "behavior = 'gift_card' and hidden != 1"
  validate :validify

  I18n.locale = AppConfig.locale
  REBATE_TYPES = [
    [I18n.t('views.forms.percent_off'),'percent'],
    [I18n.t('views.forms.fixed_amount_off'),'fixed']
  ]

  def nonrefunded_item_count
    self.order_items.visible.where(:refunded => false).count
  end

  def has_cute_credit_message?
    config = ActiveRecord::Base.configurations[Rails.env].symbolize_keys
    conn = Mysql2::Client.new(config)
    sql = "SELECT count(*) as num FROM cute_credit.cute_credit_messages where ref_id = '#{self.id}'"
    cnt = conn.query(sql).first
    if cnt then
      num = cnt["num"]
    else
      num = 0
    end
    if num > 0 then
      return true
    else
      return false
    end
  end
  def cute_credit_message
    config = ActiveRecord::Base.configurations[Rails.env].symbolize_keys
    conn = Mysql2::Client.new(config)
    sql = "SELECT * FROM cute_credit.cute_credit_messages where ref_id = '#{self.id}'"
    rec = conn.query(sql).first
    return rec
  end
  def add_payment_methods(params)
    if params[:payment_methods] then
      npms = []
      params[:payment_methods].each do |pm|
        m = PaymentMethod.new(pm)
        m.order_id = self.id
        if m.save then
          self.payment_methods << m
        end
      end
    end
  end
  def remove_payment_method(id)
    pm = self.payment_methods.find_by_id(id)
    if pm then
      pm.destroy
      self.payment_methods.reload
    end
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
  def validify
    if self.total.nil? then
      self.total = 0.0
    end
    if not self.user and not self.employee then
      errors.add(:user_id,I18n.t("system.errors.order_must_have_user"))
    end
    if not self.vendor then
      errors.add(:vendor_id, I18n.t("system.errors.order_vendor_required"))
    end
    if not self.cash_register then
      errors.add(:cash_register_id,I18n.t("system.errors.order_register_required"))
    end
  end
  def total=(p)
    return if self.paid == 1
    p = self.string_to_float(p)
    p = p * -1 if self.buy_order == true and p > 0
    write_attribute(:total,p) 
  end
  def front_end_change=(p)
    if self.paid == 1 then
      return
    end
    write_attribute(:front_end_change,self.string_to_float(p)) 
  end
  def rebate=(p)
    return if self.paid == 1
    write_attribute(:rebate,self.string_to_float(p)) 
  end
  def subtotal=(p)
    return if self.paid == 1
    write_attribute(:subtotal,self.string_to_float(p)) 
  end
  def tax=(p)
    return if self.paid == 1
    write_attribute(:tax,self.string_to_float(p)) 
  end
  def toggle_buy_order=(x)
    return if self.paid == 1
    toggle_buy_order(x)
  end
  def toggle_buy_order(x)
    return if self.paid == 1
    if self.buy_order then
      self.update_attribute(:buy_order, false)
    else
      self.update_attribute(:buy_order,true)
    end
    self.order_items.each do |oi|
      oi.price = oi.discover_price(oi.item)
      oi.calculate_total
    end
  end
  def toggle_lock(type)
    if type == 'total' then
      self.update_attribute(:total_is_locked,!self.total_is_locked)
    elsif type == 'subtotal' then
      self.update_attribute(:subtotal_is_locked,!self.subtotal_is_locked)
    elsif type == 'tax' then
      self.update_attribute(:tax_is_locked,!self.tax_is_locked)
    end
  end
  #
  def get_owner
    return self.employee if self.employee
    return self.user if self.user  
  end
  # This function is mainly used by the api
  def skus=(list)
    list.each do |s|
      if s.class == Array then
        qty = s[1]
        s = s[0]
      end
      item = Item.get_by_code(s)
      if item then
        if item.class == LoyaltyCard then
          self.customer = item
        else
          oi = self.add_item(item)
          if qty then
            oi.quantity = qty
          end
        end
      end #if item
    end # end list.each
  end

  #
	def add_item(item)
    return if self.paid == 1
	  if not item then
	    GlobalErrors.append("system.errors.item_not_found",self)
	    return false
	  end
	  if item.is_gs1 == true then
      # this is a gs1 item.
      oi = OrderItem.new
      oi.set_item(item)
      oi.is_valid = true
      oi.order_id = self.id
      self.order_items << oi
      update_self_and_save
      return oi
    end
    oi = self.order_items.visible.find_by_item_id(item.id)
    if oi and not oi.is_buyback and not oi.no_inc then
      # just increment OrderItem
      oi.update_attribute(:quantity, oi.quantity + 1)
      update_self_and_save
      return oi
    end

    # create new OrderItem
	  oi = OrderItem.new
	  if oi.nil? then
	    oi = OrderItem.new # MF: doesn't make sense?
	  end
	  oi.order_id = self.id
	  oi.no_inc = true if GlobalData.params and GlobalData.params.no_inc
	  ret = oi.set_item(item)
	  return oi if not ret
	  # self.order_items << oi
	  # update_self_and_save
	  return oi
	end

  #
	def change_given
	  ttl = 0.0
	  self.payment_methods.each do |pm|
	    ttl += pm.amount
	  end
	  return 0 if ttl == 0.0
	  return ttl - self.total
	end
	#
	#def coupons
	#  @cs ||= order_items.where(:behavior => 'coupon') #trying to speed things up a bit.
	#  if not @cs.any? then
	#    return []
	#  end
	#  return @cs 
	#end
	#
	def remove_order_item(oi)
	  if self.paid == 1 and not $User.is_technician? then
	    GlobalErrors.append("system.errors.cannot_edit_completed_order")
	    return
	  end
	  nl = []
	  roi = nil
	  order_items.each do |oo|
	    if oo == oi
	      # so we won't add it, but now we need to do some magic if it is a coupon
        oo.update_attribute :hidden, 1
	      if oi.behavior == 'coupon' then
	        roi = self.order_items.joins(:item).readonly(false).where("items.sku = '#{oi.item.coupon_applies}'")
	        if roi then
	          roi = roi.first
	          roi.update_attribute(:coupon_amount,0) if roi
	          roi.update_attribute(:coupon_applied, false) if roi
	        end
	      end
	    end
	  end
	  @cs = nil
	  @gfs = nil
	  update_self_and_save
	  return roi
	end
	#
	#def gift_cards
	#  @gfs ||= order_items.where(:behavior => 'gift_card')
	#  return [] if not @gfs.any?
	#  return @gfs
	#end
	#
	def coupon_for(sku)
	  cps = []
	  coupons.each do |oi|
	    if oi.item.coupon_applies == sku then
	      cps << oi
	    end
	  end if coupons
	  if not cps.any? then
	    return false
	  else
	    return cps
	  end
	end
	#
	def apply_coupon(cp,oi)
	end
	#
	def calculate_totals(speedy = false)
	  if self.paid == 1 and not $User.is_technician? then
	    #GlobalErrors.append("system.errors.cannot_edit_completed_order",self)
	    return
	  end
	  unless speedy == true then
	    # puts "Speedy is not true"
      # EVERYTHING is recalculated in normal mode only
      self.total = 0 unless self.total_is_locked and not self.total.nil?
      self.subtotal = 0 unless self.subtotal_is_locked and not self.subtotal.nil?
      self.tax = 0 unless self.tax_is_locked and not self.tax.nil?
      self.order_items.visible.reload.order("id ASC").each do |oi|
        if oi.item.nil? then
          remove_order_item(oi)
          next
        end
        if oi.refunded then
          next
        end
        if self.buy_order and oi.is_buyback then
          oi.update_attribute :is_buyback, false
        end
        # Coupons are not handled here, they are handled at the end of the order.
        if oi.item_type.behavior == 'normal' or oi.item_type.behavior == 'gift_card' then
          price = oi.calculate_total self.subtotal
          puts "price from #{oi.item.sku} is #{price}"
          if oi.is_buyback and not self.buy_order then
            if price > 0 then
              oi.update_attribute(:price, price * -1)
              self.subtotal = self.subtotal - price
            else
              self.subtotal = self.subtotal + price  
            end
          else
            if oi.behavior == 'gift_card' and oi.item.activated then
              self.subtotal = self.subtotal - oi.price
            else
              b = self.subtotal
              self.subtotal = self.subtotal + price
              a = self.subtotal
              puts "Check:  #{b} + #{price} = #{a}"
            end
          end
          # regular items are never activated, 
          # if a gift card is not activated, it 
          # counts as a normal item, if it is
          # activated, then it is not a taxable item, 
          # as it is not being sold.
            if not oi.item.activated then
              self.tax ||= 0
              self.tax += oi.calculate_tax unless self.tax_is_locked or oi.is_buyback == true
            end
        end
      end
      # puts "Here I am in order, #{self.subtotal}"
      # Now let's consider Store Wide Discounts, for item/location/percent specific discounts,
      # see Item.price    
      if not self.subtotal_is_locked then
        @vendor_discounts ||= Discount.scopied.where("applies_to = 'Vendor' and amount_type = 'fixed'")
        dids = []
        self.discount_amount = 0
        @vendor_discounts.each do |discount|
            self.subtotal -= discount.amount
            self.discount_amount += discount.amount
            dids << discount.id
        end
        if dids.any? then
          self.discount_ids = dids
        end
        begin
          if GlobalData.conf and self.lc_points then
            disc = GlobalData.conf.dollar_per_lp * self.lc_points
            self.subtotal -= disc
            self.update_attribute(:lc_discount_amount, disc)
          end
        rescue
          GlobalErrors.append_fatal("system.errors.lp_calculation_failed",self)
        end
      end
      if not self.subtotal_is_locked and not self.rebate.nil? then
        self.subtotal -= self.calculate_rebate
      end
      #if self.subtotal < 0 then
        #self.subtotal = 0
      #end
      puts "AND FINALLY: #{self.subtotal} + #{self.tax} "
      self.total = self.subtotal unless self.total_is_locked
    else
      # Here we do speedy version calculations for show_payment_ajax processing
      self.total = 0 if self.total.nil?
      self.subtotal = self.total
      self.calculate_tax
      Order.connection.execute("update orders set total = #{self.total}, subtotal = #{self.subtotal}, tax = #{self.tax} where id = #{self.id}")
    end
    # Coupon stuff is done in both speedy and normal modes
	  coupons.each do |oi|
      # If the coupn applies to an entire order, like $10 off any order etc
      # Users should be able to specify this in their own language.
      if oi.item.coupon_applies == I18n.t('views.single_words.order') then
        if oi.item.coupon_type == 1 then #percent off coupon type
          self.total -= (oi.price / 100) * self.total
        elsif oi.item.coupon_type == 2 then #fixed amount off
          self.total -= oi.price
        elsif oi.item.coupon_type == 3 then
          GlobalErrors.append("system.errors.coupon_cannot_be_buy_one_get_one", self,{:sku => oi.item.sku, :applies => oi.item.coupon_applies})
        end
      end
    end if coupons and not self.total_is_locked
    self.update_attribute(:total, self.total)
    # puts "End of calculate_totals, total is: #{self.total}"
	end

	#
  def calculate_tax
    # Add together tax for all items in order
    self.tax = 0 if self.tax.nil?
    return self.tax if self.tax_is_locked
    #res = OrderItem.connection.execute("select sum(tax) as taxtotal from order_items where order_id = #{self.id} and behavior = 'normal' and is_buyback is false")
    taxttl = OrderItem.where("order_id = #{self.id} and behavior = 'normal' and is_buyback is false").sum(:tax)
    taxttl.nil? ? self.tax = 0 : self.tax = taxttl.to_f.round(2)
  end
  #
  def gross
    if self.vendor.calculate_tax then
      taxttl = OrderItem.where("order_id = #{self.id} and behavior != 'coupon' and is_buyback is false and activated is false").sum(:tax)
      return self.subtotal + taxttl
    else
      return self.subtotal
    end
  end
  #
	def calculate_rebate
	  amnt = 0.0
	  if self.subtotal.nil? then self.subtotal = 0 end
    amnt = (self.subtotal * (self.rebate/100)) if self.rebate_type == 'percent'
    amnt = self.rebate if self.rebate_type == 'fixed'
    return amnt
	end
	#
	def update_self_and_save
		calculate_totals
		save!
	end
	#
	def complete=(api_called=nil)
	  self.complete
	end
	#
  def complete
    log_action "Starting complete order. Drawer amount is: #{GlobalData.salor_user.get_drawer.amount}"
    log_action "User Is: #{GlobalData.salor_user.username}"
    log_action "DrawerId Is: #{GlobalData.salor_user.get_drawer.id}"
    log_action "OrderId Is: #{self.id}"
    self.update_attribute :paid, 1
    self.update_attribute :created_at, Time.now
    self.update_attribute :drawer_id, $User.get_drawer.id
    self.reload
    begin # so if all this doesn't work, then the order won't complete...
      log_action "Updating quantities"
      order_items.visible.each do |oi|
        # These methods are defined on OrderItem model.
        oi.set_sold
        oi.update_quantity_sold
        oi.update_cash_made
      end
      log_action "Updating Category Gift Cards"
      activate_gift_cards
      
      update_self_and_save
      ottl = self.get_drawer_add
      if self.buy_order then
        ottl *= -1 if ottl < 0
        create_drawer_transaction(self.get_drawer_add,:payout,{:tag => "CompleteOrder"})
        #GlobalData.salor_user.get_drawer.update_attribute(:amount,GlobalData.salor_user.get_drawer.amount - self.total)
      elsif self.total < 0 then
        ottl *= -1 if ottl < 0
        create_drawer_transaction(self.get_drawer_add,:payout,{:tag => "CompleteOrder"})
      else

        $User.meta.update_attribute :last_order_id, self.id
        create_drawer_transaction(ottl,:drop,{:tag => "CompleteOrder"})
        log_action("OID: #{self.id} USER: #{$User.username} OTTL: #{ottl} DRW: #{$User.get_drawer.amount}")
        #GlobalData.salor_user.get_drawer.update_attribute(:amount,GlobalData.salor_user.get_drawer.amount + ottl)
      end
      lc = self.loyalty_card
      self.lc_points = 0 if self.lc_points.nil?
      if lc and not self.lc_points.nil? and not lc.points.nil? then
        if self.lc_points > lc.points then
          self.lc_points = lc.points
        end
        lc.update_attribute(:points,lc.points - self.lc_points)
        np = GlobalData.conf.lp_per_dollar * self.subtotal
        lc.update_attribute(:points,lc.points + np)
      end
    rescue
      # puts $!.to_s
      self.update_attribute :paid, 0
      GlobalErrors.append_fatal("system.errors.order_failed",self)
      log_action $!.to_s
      puts $!.to_s
    end
    log_action "Ending complete order. Drawer amount is: #{GlobalData.salor_user.get_drawer.amount}"
  end
  def activate_gift_cards
    self.gift_cards.each do |gc|
      if gc.item.activated then
        gc.item.amount_remaining -= gc.price
        gc.item.amount_remaining = 0 if gc.item.amount_remaining < 0
        gc.item.save
      else
        gc.item.update_attribute(:activated,true)
        gc.item.update_attribute(:amount_remaining, gc.item.base_price)
      end
    end
  end
  def get_drawer_add
    ottl = self.subtotal
    self.payment_methods.each do |pm|
      next if pm.internal_type == 'InCash'
      ottl -= pm.amount
    end
    puts "get_drawer_add returning #{ottl}"
    return ottl
  end
  def get_in_cash_amount
    pm = self.payment_methods.where(:internal_type => 'InCash').first
    return pm.amount if pm
    return 0
  end
  def activate_gift_card(id,amount)
    log_action "## Activating Gift Card"
    amount = string_to_float(amount)
    if id.class == OrderItem then
      oi = id
    else
      oi = self.order_items.visible.find_by_id(id)
    end
    if not oi then
      log_action"## not oi, returning"
      return false 
    end
    if not oi.item.activated then
      log_action "Setting activated..."
      oi.item.update_attribute(:activated,true)
      oi.item.update_attribute(:amount_remaining, oi.item.base_price)
      oi.update_attribute(:activated, true)
    end
    if oi.item.amount_remaining < amount then
      log_action "updating attr to #{oi.item.amount_remaining}"
      oi.update_attribute(:price,oi.item.amount_remaining)
      oi.update_attribute(:activated, true)
    else
      log_action "updating attr"
      oi.update_attribute(:price,amount)
      oi.update_attribute(:activated, true)
    end
    return oi
  end

  #
  def create_drawer_transaction(amount,type,opts={})
    dt = DrawerTransaction.new(opts)
    dt.amount = amount
    dt[type] = true
    dt.drawer_id = $User.get_drawer.id
    dt.drawer_amount = $User.get_drawer.amount
    dt.order_id = self.id
    if dt.amount < 0 then
      dt.payout = true
      dt.drop = false
      dt.amount *= -1
    end
    if dt.save then
      if type == :payout then
        $User.get_drawer.update_attribute(:amount,GlobalData.salor_user.get_drawer.amount - dt.amount)
      elsif type == :drop then
        $User.get_drawer.update_attribute(:amount,GlobalData.salor_user.get_drawer.amount + dt.amount)
      end
      $User.reload
    end
  end
    
  #
  def create_refund_payment_method(amount, refund_payment_method)
    PaymentMethod.create(:internal_type => (refund_payment_method + 'Refund'), 
                         :name => (refund_payment_method + 'Refund'), 
                         :amount => - amount, 
                         :order_id => self.id
    ) # end of PaymentMethod.create
  end

  def toggle_refund(x, refund_payment_method)
    if not $User.get_drawer.amount >= self.total then
      GlobalErrors.append_fatal("system.errors.not_enough_in_drawer",self)
      return
    end
    if self.refunded then
      # this is disabled in the view currently
      #self.update_attribute(:refunded, false)
      #create_drawer_transaction(self.total,:drop)
    else
      return if (GlobalData.salor_user.get_drawer.amount - self.total) < 0

      self.update_attribute(:refunded, true)
      self.update_attribute(:refunded_by, GlobalData.salor_user.id)
      self.update_attribute(:refunded_by_type, GlobalData.salor_user.class.to_s)
      if refund_payment_method == 'InCash'
        opts = {:tag => 'OrderRefund',:is_refund => true,:amount => self.total, :notes => I18n.t("views.notice.order_refund_dt",:id => self.id)}
        create_drawer_transaction(self.total, :payout, opts)
      else
        create_refund_payment_method(self.total, refund_payment_method)
      end
      self.order_items.visible.each do |oi|
        if not oi.refunded == true then
          oi.toggle_refund(nil, refund_payment_method)
        end
      end  
    end
  end
  def refund_total
    t = 0
    self.order_items.where("refunded = 1").each do |oi|
      oi.total = 0 if oi.total.nil?
      t = t + oi.total
    end
    t -= self.calculate_rebate
    return t
  end

  def to_json
    self.total = 0 if self.total.nil?
    attrs = {
      :total => self.total.round(2),
      :rebate_type => self.rebate_type_display,
      :rebate => self.rebate.round(2),
      :customer => false,
      :lc_points => self.lc_points,
      :id => self.id,
      :buy_order => self.buy_order,
      :tag => self.tag.nil? ? I18n.t("system.errors.value_not_set") : self.tag
    }
    if self.customer then
      attrs[:customer] = self.customer
      attrs[:loyalty_card] = self.customer.loyalty_card
    end
    attrs.to_json
  end
  def order_items_as_array
    items = []
    self.order_items.visible.each do |oi|
      items << oi.to_json
    end
    return items
  end
  # I moved this stuff here to clean up the views and
  # to make it easier to fix as there were some errors.
  def payment_method_sums
    sums = Hash.new
      self.payment_methods.each do |pm|
        s = pm.internal_type.to_sym
        next if s.nil?
        sums[s] = 0 if sums[s].nil?
        pm.amount = 0 if pm.amount.nil?
        sums[s] += pm.amount
      end
    return sums
  end

  def payment_display
    if self.payment_methods.length > 1 then
      return ["Mix",self.total]
    else
      pm = self.payment_methods.first
      return ['Unk',0] if pm.nil?
      return [pm.internal_type,self.total]
    end
  end
  def get_user
    return self.employee if self.employee
    return self.user if self.user
    if AppConfig.standalone then
      return User.first
    end
    raise "Cannot return Employee on this order."
  end
  
  def paylife_blurb
    
  end
  
  def get_report
    sum_taxes = Hash.new
    TaxProfile.scopied.each { |t| sum_taxes[t.id] = 0 }
    subtotal1 = 0
    discount_subtotal = 0
    rebate_subtotal = 0
    refund_subtotal = 0
    coupon_subtotal = 0
    list_of_items = ''
    self.order_items.visible.each do |oi|

      item_total = 0 if item_total.nil?
      oi.price = 0 if oi.price.nil?
      oi.quantity = 0 if oi.quantity.nil?
      item_price = 0 if item_price.nil?
      name = oi.item.name

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
            # only percent order rebates will be equally distributed on all OrderItems
            refund_subtotal += new_item_total * ( 1 - ( 1 - self.rebate / 100.0 ))
          end
        end
        item_price = 0
        item_total = 0
        new_item_price = 0
        new_item_total = 0
      end

      # Price calculation for taxes
      if not oi.refunded
        sum_taxes[oi.tax_profile.id] += new_item_total # start with unmodified price
        if self.rebate > 0
          if self.rebate_type == 'percent'
            # distribute % order rebate euqally on all order items
            sum_taxes[oi.tax_profile.id] -= new_item_total * ( 1 - ( 1 - self.rebate / 100.0 ))
          end
          if self.rebate_type == 'fixed'
            # distribute fixed order rebate euqally on all order items
            sum_taxes[oi.tax_profile.id] -= self.rebate / self.nonrefunded_item_count # dividing is safe because it's inside of not oi.refunded
          end
        end
      end

      subtotal1 += item_total

      # THE FOLLOWING IS THE LINE GENERATION

      # NORMAL ITEMS
      if oi.behavior == 'normal'
        if oi.quantity == Integer(oi.quantity)
          # integer quantity
          list_of_items += "%s %19.19s %6.2f  %3u   %6.2f\n" % [oi.item.tax_profile.letter, name, item_price, oi.quantity, item_total]
        else
          # float quantity (e.g. weighed OrderItem)
          list_of_items += "%s %19.19s %6.2f  %5.3f %6.2f\n" % [oi.item.tax_profile.letter, name, item_price, oi.quantity, item_total]
        end
      end

      # GIFT CARDS
      if oi.behavior == 'gift_card'
        list_of_items += "%s %19.19s %6.2f  %3u   %6.2f\n" % [oi.item.tax_profile.letter, name, item_price, oi.quantity, item_total]
      end

      # COUPONS
      if oi.behavior == 'coupon'
        if oi.item.coupon_type == 1
          # percent coupon
          list_of_items += "%s %19.19s %6.1f%% %3u   %6.2f\n" % [oi.item.tax_profile.letter, name, item_price, oi.quantity, item_total]
        elsif oi.item.coupon_type == 2
          # fixed amount coupon
          list_of_items += "%s %19.19s %6.2f  %3u   %6.2f\n" % [oi.item.tax_profile.letter, name, item_price, oi.quantity, item_total]
        elsif oi.item.coupon_type == 3
          # b1g1 coupon
          list_of_items += "%s %19.19s %6.2f  %3u   %6.2f\n" % [oi.item.tax_profile.letter, name, item_price, oi.quantity, item_total]
        end
      end

      # DISCOUNTS
      if oi.discount_applied and not self.buy_order
        if oi.quantity == Integer(oi.quantity)
          # integer quantity
          list_of_items += "%s %19.19s %6.2f  %3u   %6.2f\n" % [oi.item.tax_profile.letter, I18n.t('printr.order_receipt.discount') + ' ' + oi.discounts.first.name, discount_price, oi.quantity, discount_total]
        else
          # float quantity
          list_of_items += "%s %19.19s %6.2f  %5.3f %6.2f\n" % [oi.item.tax_profile.letter, I18n.t('printr.order_receipt.discount') + ' ' + oi.discounts.first.name, discount_price, oi.quantity, discount_total]
        end
      end

      # REBATES
      if oi.rebate and oi.rebate > 0
        if oi.quantity == Integer(oi.quantity)
          # integer quantity
          list_of_items += "%s %19.19s %6.2f  %3u   %6.2f\n" % [oi.item.tax_profile.letter, I18n.t('printr.order_receipt.rebate'), rebate_price, oi.quantity, rebate_total]
        else
          # float quantity
          list_of_items += "%s %19.19s %6.2f  %5.3f %6.2f\n" % [oi.item.tax_profile.letter, I18n.t('printr.order_receipt.rebate'), rebate_price, oi.quantity, rebate_total]
        end
      end

    end # order_items.each do


    if self.lc_points? and not self.refunded
      lc_points_discount = - self.vendor.salor_configuration.dollar_per_lp * self.lc_points
      subtotal1 += lc_points_discount
    end

    display_subtotal1 = not(self.rebate.zero? and discount_subtotal.zero? and rebate_subtotal.zero?)

    subtotal2 = subtotal1
    if not discount_subtotal.zero?
      display_subtotal2 = true
      subtotal2 += discount_subtotal
    end

    subtotal3 = subtotal2
    if not rebate_subtotal.zero?
      display_subtotal3 = true
      subtotal3 += rebate_subtotal
    end

    subtotal4 = subtotal3
    if not coupon_subtotal.zero?
      display_subtotal4 = true
      subtotal4 += coupon_subtotal
    end

    order_rebate = 0
    if self.rebate_type == 'percent' and not self.rebate.zero?
      percent_rebate_amount = - subtotal4 * self.rebate / 100.0
      percent_rebate = self.rebate
      order_rebate = percent_rebate_amount
    elsif self.rebate_type == 'fixed' and not self.rebate.zero?
      fixed_rebate_amount = - self.rebate
      order_rebate = fixed_rebate_amount
    end
    subsubtotal = subtotal4 + order_rebate

    paymentmethods = Hash.new
    self.payment_methods.each do |pm|
      next if pm.amount.zero?
      paymentmethods[pm.name] = pm.amount
    end

    list_of_taxes = ''
    TaxProfile.scopied.each do |tax|
      next if sum_taxes[tax.id] == 0
      fact = tax.value / 100.00
      net = sum_taxes[tax.id] / (1.00 + fact)
      gro = sum_taxes[tax.id]
      vat = gro - net
      list_of_taxes += "       %s: %2i%% %7.2f %7.2f %8.2f\n" % [tax.letter,tax.value,net,vat,gro]
    end

    if self.customer
      customer = Hash.new
      customer[:company_name] = self.customer.company_name
      customer[:first_name] = self.customer.first_name
      customer[:last_name] = self.customer.last_name
      customer[:street1] = self.customer.street1
      customer[:street2] = self.customer.street2
      customer[:postalcode] = self.customer.postalcode
      customer[:city] = self.customer.city
      customer[:current_loyalty_points] = self.loyalty_card.points
    end

    report = Hash.new
    report[:discount_subtotal] = discount_subtotal
    report[:rebate_subtotal] = rebate_subtotal
    report[:refund_subtotal] = refund_subtotal
    report[:coupon_subtotal] = coupon_subtotal
    report[:list_of_items] = list_of_items
    report[:lc_points_discount] = lc_points_discount
    report[:lc_points] = lc_points
    report[:subtotal1] = subtotal1
    report[:display_subtotal1] = display_subtotal1
    report[:subtotal2] = subtotal2
    report[:display_subtotal2] = display_subtotal2
    report[:subtotal3] = subtotal3
    report[:display_subtotal3] = display_subtotal3
    report[:subtotal4] = subtotal4
    report[:display_subtotal4] = display_subtotal4
    report[:percent_rebate_amount] = percent_rebate_amount
    report[:percent_rebate] = percent_rebate
    report[:fixed_rebate_amount] = fixed_rebate_amount
    report[:subsubtotal] = subsubtotal
    report[:paymentmethods] = paymentmethods
    report[:change_given] = self.change_given
    report[:list_of_taxes] = list_of_taxes
    report[:customer] = customer
    report[:unit] = I18n.t('number.currency.format.friendly_unit')

    return report
  end
  
  # new methods from test
  
  def self.generate
    if GlobalData.salor_user.get_meta.order_id then
      # puts "OrderId found"
      o = Order.find(GlobalData.salor_user.get_meta.order_id)
      if o and (not o.paid and not o.order_items.any?) then
        # We already have an empty order.
        return o
      end
    end
    o = Order.new(:tax => 0.0, :subtotal => 0.0, :total => 0.0)
    o.set_model_owner
    if o.save then
      # puts "Updating :order_id"
    else
      # puts o.errors.inspect
    end
    GlobalData.salor_user.get_meta.update_attribute :order_id, o.id
    return o
  end
  def belongs_to_current_user?
    if not self.get_user == GlobalData.salor_user then
      return false
    end
    return true
  end
  # {END}
end
