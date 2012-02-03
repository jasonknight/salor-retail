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
	include SalorScope
  include SalorError
  include SalorBase
  include SalorModel
	has_many :order_items, :dependent => :delete_all
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
  has_many :coupons, :class_name => "OrderItem", :conditions => {:behavior => "coupon" }
  has_many :gift_cards, :class_name => "OrderItem", :conditions => {:behavior => "gift_card" }
  validate :validify
  
  REBATE_TYPES = [
    [I18n.t('views.forms.percent_off'),'percent'],
    [I18n.t('views.forms.fixed_amount_off'),'fixed']
  ]
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
    write_attribute(:total,self.string_to_float(p)) 
  end
  def front_end_change=(p)
    write_attribute(:front_end_change,self.string_to_float(p)) 
  end
  def rebate=(p)
    
    write_attribute(:rebate,self.string_to_float(p)) 
  end
  def subtotal=(p)
    write_attribute(:subtotal,self.string_to_float(p)) 
  end
  def tax=(p)
    write_attribute(:tax,self.string_to_float(p)) 
  end
  def toggle_buy_order=(x)
    toggle_buy_order(x)
  end
  def toggle_buy_order(x)
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
    oi = OrderItem.new
	  if oi.nil? then
	    oi = OrderItem.new
	  end
	  oi.order_id = self.id
	  oi.no_inc = true if GlobalData.params and GlobalData.params.no_inc
	  ret = oi.set_item(item)
	  return oi if not ret
	  # self.order_items << oi
	  # update_self_and_save
	  return oi
	end
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
	  if self.paid == 1 then
	    GlobalErrors.append("system.errors.cannot_edit_completed_order")
	    return
	  end
	  nl = []
	  roi = nil
	  order_items.each do |oo|
	    if oo == oi
	      # so we won't add it, but now we need to do some magic if it is a coupon
	      if oi.behavior == 'coupon' then
	        roi = self.order_items.joins(:item).where("items.sku = '#{oi.item.coupon_applies}'")
	        if roi then
	          roi = roi.first
	          roi.update_attribute(:coupon_amount,0) if roi
	          roi.update_attribute(:coupon_applied, false) if roi
	        end
	      end
	      next
	    end
	    nl << oo
	  end
	  self.order_items = nl
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
	  if self.paid == 1 then
	    #GlobalErrors.append("system.errors.cannot_edit_completed_order",self)
	    return
	  end
	  unless speedy == true then
	    # puts "Speedy is not true"
      # EVERYTHING is recalculated in normal mode only
      self.total = 0 unless self.total_is_locked and not self.total.nil?
      self.subtotal = 0 unless self.subtotal_is_locked and not self.subtotal.nil?
      self.tax = 0 unless self.tax_is_locked and not self.tax.nil?
      self.order_items.reload.each do |oi|
        if oi.item.nil? then
          remove_order_item(oi)
          next
        end
        if oi.refunded then
          next
        end
        # Coupons are not handled here, they are handled at the end of the order.
        if oi.item_type.behavior == 'normal' or oi.item_type.behavior == 'gift_card' then
          price = oi.calculate_total
          if oi.is_buyback and not self.buy_order then
            if price > 0 then
              oi.update_attribute(:price, price * -1)
              self.subtotal -= price
            else
              self.subtotal += price  
            end
          else
            if oi.behavior == 'gift_card' and oi.item.activated then
              self.subtotal -= oi.price
            else
              self.subtotal += price
            end
          end
          # regular items are never activated, 
          # if a gift card is not activated, it 
          # counts as a normal item, if it is
          # activated, then it is not a taxable item, 
          # as it is not being sold.
          begin
            if not oi.item.activated then
              self.tax ||= 0
              self.tax += oi.calculate_tax unless self.tax_is_locked or oi.is_buyback == true
            end
          rescue

          end
        end
      end
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
      return self.total + taxttl
    else
      return self.total
    end
  end
  #
	def calculate_rebate
	  amnt = 0.0
	  if self.subtotal.nil? then self.subtotal = 0 end
    if self.rebate_type == 'fixed' then
      amnt = self.rebate
    elsif self.rebate_type == 'percent' then
      amnt = (self.subtotal * (self.rebate/100))
    end
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
    begin # so if all this doesn't work, then the order won't complete...
      log_action "Updating quantities"
      order_items.each do |oi|
        # These methods are defined on OrderItem model.
        oi.set_sold
        oi.update_quantity_sold
        oi.update_cash_made
      end
      log_action "Updating Category Gift Cards"
      activate_gift_cards
      
      update_self_and_save
  
      if self.buy_order then
        create_drawer_transaction(ottl,:payout,{:tag => "CompleteOrder"})
        #GlobalData.salor_user.get_drawer.update_attribute(:amount,GlobalData.salor_user.get_drawer.amount - self.total)
      elsif self.total < 0 then
        create_drawer_transaction(self.total,:payout,{:tag => "CompleteOrder"})
      else
        ottl = self.get_drawer_add
        GlobalData.salor_user.meta.update_attribute :last_order_id, self.id
        create_drawer_transaction(ottl,:drop,{:tag => "CompleteOrder"})
        log_action("OID: #{self.id} USER: #{GlobalData.salor_user.username} OTTL: #{ottl} DRW: #{GlobalData.salor_user.get_drawer.amount}")
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
        gc.item.update_attribute(:amount_remaining, gc.price)
      end
    end
  end
  def get_drawer_add
    if self.total < 0 then
      return self.total
    end
    ottl = self.total
    self.payment_methods.each do |pm|
      next if pm.internal_type == 'InCash'
      ottl -= pm.amount
    end
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
      oi = self.order_items.find_by_id(id)
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
  def create_drawer_transaction(amount,type,opts={})
    dt = DrawerTransaction.new(opts)
    dt.amount = amount
    dt[type] = true
    dt.drawer_id = GlobalData.salor_user.get_drawer.id
    dt.drawer_amount = GlobalData.salor_user.get_drawer.amount
    dt.order_id = self.id
    if dt.save then
      if type == :payout then
        GlobalData.salor_user.get_drawer.update_attribute(:amount,GlobalData.salor_user.get_drawer.amount - dt.amount)
      elsif type == :drop then
        GlobalData.salor_user.get_drawer.update_attribute(:amount,GlobalData.salor_user.get_drawer.amount + dt.amount)
      end
      GlobalData.vendor.open_cash_drawer
    end
  end
  def toggle_refund(x)
    if self.refunded then
      self.update_attribute(:refunded, false)
      #create_drawer_transaction(self.total,:drop)
    else
      self.update_attribute(:refunded, true)
      self.update_attribute(:refunded_by, GlobalData.salor_user.id)
      self.update_attribute(:refunded_by_type, GlobalData.salor_user.class.to_s)
      self.order_items.each do |oi|
        if not oi.refunded then
          oi.toggle_refund(nil)
        end
      end
      opts = {:tag => I18n.t("activerecord.models.drawer_transaction.refund"),:is_refund => true,:amount => self.total, :notes => I18n.t("views.notice.order_refund_dt",:id => self.id)}
      create_drawer_transaction(self.total,:payout,opts)
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
  def print_receipt
    #begin
      @order = self
      @vendor = self.vendor
      @in_cash = 0
      @by_card = 0
      @by_gift_card = 0
      @other_credit = 0
      cash_register_id = GlobalData.salor_user.meta.cash_register_id
      vendor_id = GlobalData.salor_user.meta.vendor_id
      salor_user = GlobalData.salor_user
      if cash_register_id and vendor_id
        printers = VendorPrinter.where( :vendor_id => vendor_id, :cash_register_id => cash_register_id )
        Printr.new.send(printers.first.name.to_sym,'item',binding) if printers.first
      end
    #rescue
    #  GlobalErrors.append("system.errors.order_print_failure",self)
    #end
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
    self.order_items.each do |oi|
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
    text = ''
    sa = nil
    if not self.m_struct.blank? then
      pattern = /STX (M)\d\d(.)(\d)(.{20})(.{21})(.{5})(.)(.{16})(.{8})(.{6})(.{6})(.{20})(\d{8})(.{8})(.{6})(.{16}).+ ETX/
      text = self.m_struct
      sa = 'M'
    elsif not self.p_struct.blank? then
      pattern = /STX (P)\d\d(\d)(.{40})(.{16})(.{3})(.+) ETX/
      text = self.p_struct
      sa = 'P'
    end
    return '' if not sa
    match = text.match(pattern)
    jts = []
    jt = self.j_text
    jt ||= ''
    begin
      x = jt.utf8_safe_split(33)
      jts << x[0]
      jt = x[1]
    end while jt.length.to_i >= 33
    jt = jts.join("\n")
    if sa == 'P' then
      parts = match[6].split(" ")
      return "#{match[4]}\n#{parts[0]}\n#{parts[2]}\n\n#{jt}"
    elsif sa == 'M' then
      t = match[13].to_f / 100
      return "#{match[4]}\n#{match[5]}\n#{match[12]} #{match[9]}\nNr. #{match[10]}\nEUR #{t}\n\n#{jt}"
    end
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
  
end
