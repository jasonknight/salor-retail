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
class Item < ActiveRecord::Base
	include SalorScope
  include SalorError
  include SalorBase
  include SalorModel
	belongs_to :category
	belongs_to :vendor
	belongs_to :location
  belongs_to :tax_profile
  belongs_to :item_type
  belongs_to :item
  belongs_to :shipper
  has_many :actions, :as => :owner, :order => "weight asc"
  has_many :parts, :class_name => 'Item', :foreign_key => :part_id
  has_one :parent, :class_name => 'Item', :foreign_key => :child_id
  belongs_to :child, :class_name => 'Item'
  has_many :order_items



  validates_presence_of :sku
  validate :validify


  #scope :by_vendor, lambda {|vid| where(:vendor_id => vid)}
  #scope :visible, lambda { where("hidden = 0") }
  #scope :by_keywords, lambda {|keywords| where("name LIKE '%#{keywords}%' OR sku LIKE '#{keywords}%'")}

  after_create :set_amount_remaining
  
  before_save :run_actions
  COUPON_TYPES = [
      {:text => I18n.t('views.forms.percent_off'), :value => 1},
      {:text => I18n.t('views.forms.fixed_amount_off'), :value => 2},
      {:text => I18n.t('views.forms.buy_one_get_one'), :value => 3}
  ]
  REORDER_TYPES = ['default_export','tobacco_land']
  def run_actions
    if self.actions.any? then
      Action.run(self, :on_save)
    end
  end
  def parent_sku
    if self.parent then
      return self.parent.sku
    end
    ""
  end
  def child_sku
    if self.child then
      return self.child.sku
    end
    ""
  end
  def parent
    Item.find_by_child_id(self.id)
  end
  def child
    Item.find_by_id(self.child_id)
  end
  def parent_sku=(string)
    if string.empty? then
      self.parent = nil
      return
    end
    p = Item.find_by_sku(string)
    if p then
      # puts "Updating child_id of parent" + p.sku;
      p.update_attribute(:child_id,self.id)
    else
      errors.add(:parent_sku, I18n.t('system.errors.parent_sku_must_exist'))
      GlobalErrors.append_fatal("system.errors.parent_sku_must_exist")
    end
  end
  def child_sku=(string)
    if string.empty? then
      self.child = nil
      return
    end
    c = Item.find_by_sku(string)
    if c then
      self.update_attribute(:child_id,c.id)
    else
      errors.add(:child_sku, I18n.t('system.errors.child_sku_must_exist'))
      GlobalErrors.append_fatal("system.errors.child_sku_must_exist")
    end
  end
  def self.search(keywords)
    if keywords =~ /([\w]+) (\d{1,2}[\.\,]\d{1,2})/ then
      parts = keywords.match(/([\w]+) (\d{1,2}[\.\,]\d{1,2})/)
      price = SalorBase.string_to_float(parts[2])
      return Item.scopied.where("name LIKE '%#{parts[1]}%' and base_price > #{(price - 5).to_i} and base_price < #{(price + 5).to_i}")
    else
      return Item.scopied.where("name LIKE '%#{parts[1]}%'")
    end
  end
  def self.get_by_code(code)
    # Let's see if they entered a price
    pm = code.match(/(\d{1,5}[\.\,]\d{1,2})/)
    if pm and pm[1] then
      i = Item.scopied.where("sku LIKE 'DMY%' and base_price LIKE '#{code}%'") 
      if i.empty? then
        i = Item.scopied.find_or_create_by_sku("DMY" + GlobalData.salor_user.id.to_s + Time.now.strftime("%y%m%d") + rand(999).to_s)
        i.base_price = code
        i.make_valid
        i.save
        return i
      end 
      if i.respond_to? :first and i.first
        i = i.first
      end
      return i
    end # end if pm

    item = Item.scopied.find_by_sku(code)
    return item if item
    #We didn't find it, so let's see if we can parse the code.
    m = code.match(/\d{2}(\d{5})(\d{5})/)
    item = Item.scopied.find_by_sku(m[1]) if m
    if item then
      if not item.is_gs1 == true then
        item.update_attribute(:is_gs1, true)
      end
      return item
    end
    lcard = LoyaltyCard.scopied.find_by_sku(code)
    return lcard if lcard
    #oops, still haven't found it, let's creat a dummy item
    i = Item.scopied.find_or_create_by_sku(code)
    i.make_valid
    return i
  end

  def price
    conds = "(item_sku = '#{self.sku}' and applies_to = 'Item') OR (location_id = '#{self.location_id}' and applies_to = 'Location') OR (category_id = '#{self.category_id}' and applies_to = 'Category') OR (applies_to = 'Vendor' and amount_type = 'percent')"
    price = self.base_price
    discounted = false
    damount = 0
    Discount.scopied.where(conds).each do |discount|
      if discount.amount_type == 'percent' then
        d = discount.amount / 100
        damount = (self.base_price * d)
        price -= damount
      elsif discount.amount_type == 'fixed' then
        damount = discount.amount
        price -= damount
      end
      discounted = true
    end
    return [price,discounted,damount]
  end

  def base_price=(p)
    p = self.string_to_float(p)
    write_attribute(:base_price,p.to_f)
  end
  def purchase_price=(p)
    p = self.string_to_float(p)
    write_attribute(:purchase_price,p)
  end
  def amount_remaining=(p)
    write_attribute(:amount_remaining,self.string_to_float(p))
  end
  def tax_profile_id=(id)
    tp = TaxProfile.find_by_id(id)
    if tp then
      write_attribute(:tax_profile_amount,tp.value)
      write_attribute(:tax_profile_id,id)
    end
  end
  def item_type_id=(id)
    write_attribute(:behavior,ItemType.find(id).behavior)
    write_attribute(:item_type_id,id)
  end
  def height=(p)
    p = self.string_to_float(p)
    write_attribute(:height,p)
  end
  def width=(p)
    p = self.string_to_float(p)
    write_attribute(:width,p)
  end
  def weight=(p)
    p = self.string_to_float(p)
    write_attribute(:weight,p)
  end
  def length=(p)
    p = self.string_to_float(p)
    write_attribute(:length,p)
  end
  def min_quantity=(p)
    p = self.string_to_float(p)
    write_attribute(:min_quantity,p)
  end
  def packaging_unit=(p)
    p = self.string_to_float(p)
    write_attribute(:packaging_unit,p)
  end
  def part_skus=(items)
    ids = []
    vid = GlobalData.salor_user.meta.vendor_id
    items.each do |item|
      i = Item.find_by_sku(item[:sku])
      i.vendor_id = vid
      i.is_part = 1
      i.part_quantity = self.string_to_float(item[:part_quantity])
      i.save
      if i then
        ids << i.id
      end
    end
    begin
      self.part_ids = ids if ids.any?
    rescue
      GlobalErrors.append_fatal(I18n.t("system.errors.failed_to_save_parts"),self)
      GlobalErrors.append_fatal($!.message,self)
    end
  end
  def batches
    []
  end
  def batch_skus=(batches)
    ids = []
    batches.each do |batch|
      batch[:expires_on] = Date.parse(batch[:expires_on])
      b = Batch.find_or_create_by_sku(batch[:sku])
      b.set_model_owner
      b.add_item(self)
      b.update_attributes(batch)
      b.save
    end
  end

  def gift_card?
    self.item_type.behavior == 'gift_card'
  end
  def coupon?
    self.item_type.behavior == 'coupon'
  end
  def make_valid
    self.sku = self.sku.upcase
    invld = false
    if self.vendor_id.nil? then
      self.vendor_id = GlobalData.salor_user.meta.vendor_id
      invld = true
    end
    if self.name.blank? then
      self.name = I18n.t("views.dummy_item")
      invld = true
    end
    if self.quantity.nil? then
      self.quantity = 0
      invld = true
    end
    if self.quantity_sold.nil? then
      self.quantity_sold = 0
      invld = true
    end
    if self.base_price.nil? then
      self.base_price = 0
      invld = true
    end
    if not self.item_type_id then
      # puts "Setting Default ItemType"
      self.item_type_id = ItemType.find_by_behavior('normal').id
      invld = true
    end
    if not self.tax_profile then
      # puts "Setting Default TaxProfile"
      if GlobalData.tax_profiles
        tp = GlobalData.tax_profiles.find {|t| t if t.default == 1}
        if tp then
          self.tax_profile_id = tp.id
        else
          self.tax_profile_id = GlobalData.tax_profiles.first.id
        end
      end
      invld = true
    end
    if invld then
      save(:validate => false)
    end
  end
  def validify
    make_valid
    @item = Item.all_seeing.find_by_sku(self.sku)
    if not @item.nil? and not self.id == @item.id then
      errors.add(:sku, I18n.t('system.errors.sku_must_be_unique'))
      GlobalErrors.append_fatal('system.errors.sku_must_be_unique');
    end
    if self.item_type.behavior == 'coupon' then
      unless Item.find_by_sku(self.coupon_applies) then
        errors.add(:coupon_applies,I18n.t('views.item_must_exist'))
        GlobalErrors.append_fatal('views.item_must_exist');
      end
    end
  end
  def set_amount_remaining
    self.update_attribute(:amount_remaining,self.base_price)
  end
  def from_shipment_item(si)
    i = Item.find_by_sku(si.sku)
    if i then
      # puts "I is...#{si.shipment.shipper.name}"
      if si.shipment.shipper == i.vendor then
        # puts "Decrementing quantity, shipper is vendor"
        i.quantity = i.quantity - si.quantity
      else
        i.quantity = i.quantity + si.quantity
      end
      return i
    else
      # puts "No item found..."
      GlobalErrors.append_fatal("system.errors.item_not_found")
    end
    return nil
  end
  
  
  # Reorder recommendation csvs
  
  def self.recommend_reorder(type)
    shipper = Shipper.find_by_reorder_type(type)
    items = Item.where("quantity < min_quantity AND ignore_qty = 0 AND shipper_id = #{shipper.id}")
    if not items.any? then
      return nil 
    end
    # Now we need to create a shipment
    s = Shipment.new({
        :name => I18n.t("activerecord.models.shipment.default_name") + " - " + I18n.l(Time.now,:format => :salor),
        :price => items.each.inject(0) {|x,i| x += i.purchase_price},
        :receiver_id => GlobalData.salor_user.meta.vendor_id,
        :receiver_type => 'Vendor',
        :shipper => s,
        :shipment_type => ShipmentType.scopied.first
    })
    s.save
    items.each do |item|
      si = ShipmentItem.new({
          :name => item.name,
          :base_price => item.base_price,
          :category_id => item.category_id,
          :location_id => item.location_id,
          :item_type_id => item.item_type_id,
          :shipment_id => s.id,
          :sku => item.sku,
          :quantity => item.min_quantity - item.quantity
      })
      si.save
    end
    return Item.send(type.to_sym,items)
  end
  def self.tobacco_land(items)
    lines = []
    items.each do |item|
      sku = item.shipper_sku.blank? ? item.sku[0..3] : item.shipper_sku[0..3]
      lines << "%s %04d" % [sku,(item.min_quantity - item.quantity).to_i] 
    end
    return lines.join("\x0D\x0A")
  end
  def self.default_export(items)
    lines = []
    items.each do |item|
      lines << "%s\t%s\t%d\t%f" % [item.name,item.sku.to_i,(item.min_quantity - item.quantity).to_i,item.base_price] 
    end
    return lines.join("\n")
  end

  def quantity=(q)
    q = 0 if q.nil? or q.blank?
    q = q.to_s.gsub(',','.')
    q = q.to_f.round(3)
    difference = q - self.quantity
    write_attribute(:quantity, q) and return unless difference < 0 and q == q.round and self.quantity == self.quantity.round
    # continue only for integer quantities and decrementation
    difference.to_i.abs.times do
      i = self.quantity - 1
      if i == -1
        if self.parent
          # puts "Updating parent qty";
          before = self.parent.quantity
          self.parent.update_attribute :quantity, self.parent.quantity - 1
          after = self.parent.quantity
          parent_reducable = before != after
          write_attribute(:quantity, self.parent.packaging_unit - 1) if parent_reducable
        else
          b = write_attribute :quantity, 0
        end
      else
        c = write_attribute :quantity, i
      end
    end
  end
  def to_record
    attrs = self.attributes.clone
    attrs[:category] = self.category.name if self.category
    attrs[:location] = self.location.name if self.location
    attrs[:tax_profile] = self.tax_profile.name if self.tax_profile
    attrs[:parent_sku] = self.parent_sku if self.parent
    attrs[:child_sku] = self.child_sku if self.child
    attrs[:class] = self.class.to_s
    [ 
      :quantity, :quantity_sold,:created_at,
      :updated_at, :real_quantity,:quantity_buyback 
    ].each do |k|
      attrs.delete k
    end
    attrs
  end
end
