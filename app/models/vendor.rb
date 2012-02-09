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
class Vendor < ActiveRecord::Base
	include SalorScope
  include SalorModel
	belongs_to :user
	has_one :salor_configuration
	has_many :orders
	has_many :categories
	has_many :items
	has_many :locations
	has_many :employees
	has_many :cash_registers
	has_many :customers
	has_many :broken_items
	has_many :paylife_structs
	has_many :nodes
	has_many :shipments_received, :as => :receiver
	has_many :returns_sent, :as => :shipper
	has_many :shipments
	has_many :vendor_printers
  has_many :shippers, :through => :user
	has_many :discounts
	has_many :stock_locations
	has_many :shipment_items, :through => :shipments
  has_many :tax_profiles, :through => :user
	
  
	def salor_configuration_attributes=(hash)
	  if self.salor_configuration.nil? then
	    self.salor_configuration = SalorConfiguration.new hash
	    self.salor_configuration.save
	    return
	  end
	  self.salor_configuration.update_attributes(hash)
	end
  def set_vendor_printers=(printers)
    self.connection.execute("delete from vendor_printers where vendor_id = '#{self.id}'")
    ps = []
    printers.each do |printer|
      p = VendorPrinter.new(printer)
      p.vendor_id = self.id
      p.save
      ps << p.id
    end
    self.vendor_printer_ids = ps
  end
  def open_cash_drawer
	  cash_register_id = GlobalData.salor_user.meta.cash_register_id
    vendor_id = self.id
    if cash_register_id and vendor_id
      printers = VendorPrinter.where( :vendor_id => vendor_id, :cash_register_id => cash_register_id )
      Printr.new.send(printers.first.name.to_sym,'drawer_transaction',binding) if printers.first
    end
	end

  def receipt_logo_header=(data)
    write_attribute :receipt_logo_header, Escper::Image.new(data.read, :blob).to_s 
  end

  def receipt_logo_footer=(data)
    write_attribute :receipt_logo_footer, Escper::Image.new(data.read, :blob).to_s 
  end

  def logo=(data)
    write_attribute :logo_image_content_type, data.content_type.chomp
    write_attribute :logo_image, data.read
  end

  def logo_invoice=(data)
    write_attribute :logo_invoice_image_content_type, data.content_type.chomp
    write_attribute :logo_invoice_image, data.read
  end
  def get_stats
    # this method shows what features are being used, and how often.
    features = Hash.new
    features[:actions] = true if Action.scopied.count > 0
    features[:coupons] = true if OrderItem.scopied.where('coupon_amount > 0').count > 0
    features[:discounts] = true if Discount.by_vendor.all_seeing.count > 0
    features[:item_level_rebates] = true if OrderItem.scopied.where('rebate > 0').count > 0
      if features[:item_level_rebates] == true then
        features[:item_level_rebates_count] = OrderItem.scopied.where('rebate IS NOT NULL AND rebate != 0.0').count
      end
    features[:order_level_rebates] = true if Order.scopied.where('rebate > 0').count > 0
    if features[:order_level_rebates] == true then
      features[:order_level_rebates_count] = Order.scopied.where('rebate IS NOT NULL AND rebate != 0.0').count
    end
    @features = features
  end

end
