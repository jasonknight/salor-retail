# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class Shipment < ActiveRecord::Base
  include SalorScope
  include SalorBase

  belongs_to :shipper, :polymorphic => true
  belongs_to :receiver, :polymorphic => true
  belongs_to :shipment_type
  has_many :notes, :as => :notable, :order => "id desc"
  has_many :shipment_items
  belongs_to :vendor
  belongs_to :company
  belongs_to :user

  monetize :price_cents
  monetize :total_cents
  monetize :purchase_price_total_cents

  #accepts_nested_attributes_for :notes
  #accepts_nested_attributes_for :shipment_items


  #README
  # 1. The rails way would lead to many duplications
  # 2. The rails way would require us to reorganize all the translation files
  # 3. The rails way in this case is admittedly limited, by their own docs, and they suggest you implement your own
  # 4. Therefore, don't remove this code.
  def self.human_attribute_name(attrib, options={})
    begin
      trans = I18n.t("activerecord.attributes.#{attrib.downcase}", :raise => true) 
      return trans
    rescue
      SalorBase.log_action self.class, "trans error raised for activerecord.attributes.#{attrib} with locale: #{I18n.locale}"
      return super
    end
  end
  
  def receiver_shipper_list
    ret = []
    self.vendor.shippers.visible.order(:name).each do |shipper|
      ret << {:name => shipper.name, :value => 'Shipper:' + shipper.id.to_s}
    end
    self.company.vendors.visible.all.each do |vendor|
      ret << {:name => vendor.name, :value => 'Vendor:' + vendor.id.to_s}
    end
    return ret
  end
  
  def location_stock_location_list
    ret = []
    self.vendor.locations.visible.order(:name).each do |l|
      ret << [l.name, 'Location:' + l.id.to_s]
    end
    self.vendor.stock_locations.visible.all.each do |sl|
      ret << [sl.name, 'StockLocation:' + sl.id.to_s]
    end
    return ret
  end
  
  def the_receiver=(val)
    parts = val.split(':')
    self.receiver_type = parts[0]
    self.receiver_id = parts[1].to_i
    #self.save
  end
  
  def the_receiver
    return "#{self.receiver_type}:#{self.receiver_id}"
  end
  
  def the_shipper=(val)
    parts = val.split(':')
    self.shipper_type = parts[0]
    self.shipper_id = parts[1].to_i
    #self.save
  end
  
  def the_shipper
    return "#{self.shipper_type}:#{self.shipper_id}"
  end
  
  def set_notes=(notes_list)
    ids = []
    notes_list.each do |n|
      if n[:id] then
        ids << n[:id]
      else
        nnote = Note.new(n)
        nnote.save
        ids << nnote.id
      end
    end
    self.note_ids = ids
  end
  
  def set_items=(items_list)
    ids = []
    vid = self.vendor_id
    items_list.each do |li|
      ih = li[1]
      nih = {}
      ih.each do |k,v|
        nih[k.to_sym] = v
      end
      ih = nih
      next if ih[:sku].empty?
      
      if ih[:_delete].to_i == 1 then
        ih.delete(:_delete)
        next
      end
      anitem = Item.find_by_sku(ih[:sku])
      if not anitem then
        next
      end
      slocs = ih.delete(:set_stock_location_ids)
      # puts self.shipment_item_ids.inspect
      # puts ih.inspect
      if self.shipment_item_ids.include? ih[:id].to_i then
        if ShipmentItem.exists? ih[:id] then
          i = ShipmentItem.find(ih[:id])
#           raise "Existing: " + i.inspect
          i.update_attributes(ih)
          i.set_stock_location_ids = slocs
          ids << i.id
          i.save
        end
        next
      end
      ih.delete(:_delete)
      
      i = ShipmentItem.new(ih)
      i.set_stock_location_ids = slocs
      i.shipment_id = self.id
#       raise "New: " + i.inspect
      i.save
      if i then
        ids << i.id
      end
    end
    self.shipment_item_ids = ids 
    #self.save
  end

  def move_all_to_items
    if self.receiver.nil? then
      raise "Receiver is nil"
      return
    end
    self.shipment_items.each do |item|
      if item.in_stock then
        log_action I18n.t("system.errors.shipment_item_already_in_stock", :sku => item.sku)
        next
      end
      i = Item.new.from_shipment_item(item)    
      if i.save then
        item.update_attribute(:in_stock,true)
      else
        msg = []
        i.errors.full_messages.each do |error|
          msg << error
        end
        log_action I18n.t("system.errors.shipment_item_move_failed", :sku => item.sku, :error => msg.join('<br />'))
      end
    end
  end
  
  def move_shipment_item_to_item(id)
    
    if self.receiver.nil? or not self.receiver_type == 'Vendor' then
      add_salor_error("system.errors.must_set_receiver_to_vendor")
      return
    end

    i = self.shipment_items.find(id)
    if i.in_stock then
      log_action I18n.t("system.errors.shipment_item_already_in_stock", :sku => i.sku)
      return
    end
    if i then
      item = Item.new.from_shipment_item(i)
#       if item.nil? then
#         return
#       end
      if item.save then
        i.update_attribute(:in_stock,true)
      else
        # puts "##Shipment: Couldn't save ShipmentItem"
        add_salor_error(I18n.t("notifications.shipments_item_could_not_be_saved"))
        item.errors.full_messages.each do |error|
          add_salor_error(error)
        end
      end
    else
      # puts "##Shipment: Couldn't find ShipmentItem"
    end
  end
  
  
  def to_json
    attrs = {
      :id => self.id,
      :price => self.price.to_f,
      :receiver_id => self.receiver_id,
      :shipper_id => self.shipper_id,
      :shipper_type => self.shipper_type,
      :receiver_type => self.receiver_type,
      :total => self.total.to_f,
      :purchase_price_total => self.purchase_price_total.to_f,
      :name => self.name,
      :shipment_type_id => self.shipment_type_id
    }
    attrs.to_json
  end
  
  def self.shipment_items_to_json(shipment_items)
    "[#{shipment_items.collect { |si| si.to_json }.join(", ") }]"
  end
  
  def calculate_totals
    self.total_cents = self.shipment_items.visible.sum(:total_cents)
    self.purchase_price_total_cents = self.shipment_items.visible.sum(:purchase_price_total_cents)
    self.save
  end
  
  def add_shipment_item(params)
    return nil if params[:sku].blank?
    # get existing regular item
    si = self.shipment_items.visible.where(:sku => params[:sku]).first
    if si then
      log_action "Item is normal, and present, just increment"
      si.quantity += 1 
      si.calculate_totals
      si.save
      self.calculate_totals
      return si
    else
      log_action "ShipmentItem not found on Shipment. Will not increment."
    end
    

    # finally create the item
    si = ShipmentItem.new
    si.vendor = self.vendor
    si.company = self.company
    si.shipment = self
    si.quantity = 1
    si.sku = params[:sku]
    si.currency = self.vendor.currency
    
    # try to get default data from existing Items
    item = self.vendor.items.visible.find_by_sku(params[:sku])
    if item
      si.price_cents = item.price_cents
      si.purchase_price_cents = item.purchase_price_cents
      si.name = item.name
      si.tax_profile = item.tax_profile
    else
      # defaults
      si.price_cents = 0
      si.purchase_price_cents = 0
      si.name = "?"
    end
 
    si.calculate_totals
    self.shipment_items << si
    self.calculate_totals
    return si
  end
end
