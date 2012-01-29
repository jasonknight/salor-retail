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
class Shipment < ActiveRecord::Base
	include SalorScope
  include SalorError
  include SalorBase
  include SalorModel
  belongs_to :shipper, :polymorphic => true
  belongs_to :receiver, :polymorphic => true
  belongs_to :shipment_type
  has_many :notes, :as => :notable, :order => "id desc"
  has_many :shipment_items
  belongs_to :vendor
  belongs_to :user
  accepts_nested_attributes_for :notes
  accepts_nested_attributes_for :shipment_items
  before_create :set_model_owner
  TYPES = [
    {
      :value => 'new',
      :display => I18n.t("views.forms.shipment.types.new")
    },
    {
      :value => 'shipped',
      :display => I18n.t("views.forms.shipment.types.shipped")
    },
    {
      :value => 'complete',
      :display => I18n.t("views.forms.shipment.types.complete")
    },
    {
      :value => 'canceled',
      :display => I18n.t("views.forms.shipment.types.canceled")
    },
    {
      :value => 'returned',
      :display => I18n.t("views.forms.shipment.types.returned")
    },
    {
      :value => 'in_stock',
      :display => I18n.t("views.forms.shipment.types.in_stock")
    }
  ]
  def self.receiver_shipper_list()
    ret = []
    GlobalData.salor_user.get_shippers(nil).each do |shipper|
      ret << {:name => shipper.name, :value => 'Shipper:' + shipper.id.to_s}
    end
    GlobalData.salor_user.get_vendors(nil).each do |vendor|
      ret << {:name => vendor.name, :value => 'Vendor:' + vendor.id.to_s}
    end
    return ret
  end
  def the_receiver=(val)
    parts = val.split(':')
    self.update_attribute :receiver_type,parts[0]
    self.update_attribute :receiver_id,parts[1].to_i
  end
  
  def the_receiver
    return "#{self.receiver_type}:#{self.receiver_id}"
  end
  def price=(p)
    write_attribute(:price,self.string_to_float(p))
  end
  def the_shipper=(val)
    parts = val.split(':')
    self.update_attribute :shipper_type,parts[0]
    self.update_attribute :shipper_id, parts[1]
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
    vid = GlobalData.salor_user.meta.vendor_id
    items_list.each do |li|
      ih = li[1]
      nih = {}
      ih.each do |k,v|
        nih[k.to_sym] = v
      end
      ih = nih
      if ih[:_delete].to_i == 1 then
        ih.delete(:_delete)
        next
      end
      next if ih[:sku].blank?
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
          i.update_attributes(ih)
          i.set_stock_location_ids = slocs
          ids << i.id
        end
        next
      end
      ih.delete(:_delete)
      
      i = ShipmentItem.new(ih)
      i.set_stock_location_ids = slocs
      i.shipment_id = self.id
      i.save
      if i then
        ids << i.id
      end
    end
    self.shipment_item_ids = ids 
    self.save
  end

  def move_all_to_items
    if self.receiver.nil? then
      add_salor_error(I18n.t("system.errors.must_set_receiver_to_vendor"))
      return
    end
    self.shipment_items.each do |item|
      if item.in_stock then
        add_salor_error(I18n.t("system.errors.shipment_item_already_in_stock", :sku => item.sku))
        next
      end
      i = Item.new.from_shipment_item(item)
      i.make_valid
      if i.save then
        item.update_attribute(:in_stock,true)
      else
        msg = []
        i.errors.full_messages.each do |error|
          msg << error
        end
        add_salor_error(I18n.t("system.errors.shipment_item_move_failed", :sku => item.sku, :error => msg.join('<br />')))
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
      add_salor_error(I18n.t("system.errors.shipment_item_already_in_stock", :sku => i.sku))
      return
    end
    if i then
      item = Item.new.from_shipment_item(i)
      item.make_valid
      if item.nil? then
        GlobalErrors.append_fatal("system.errors.shipment_item_move_failed",:sku => i.sku, :error => I18n.t("system.errors.shipment_item_nil"))
        return
      end
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
end
