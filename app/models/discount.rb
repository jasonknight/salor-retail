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
class Discount < ActiveRecord::Base
  include SalorBase
	include SalorScope
  include SalorModel
  belongs_to :vendor
  belongs_to :location
  belongs_to :category
  has_and_belongs_to_many :order_items
  has_and_belongs_to_many :orders
  
  APPLIES = [
    [I18n.t("activerecord.models.vendor.one"),"Vendor"],
    [I18n.t("activerecord.models.location.one"),"Location"],
    [I18n.t("activerecord.models.category.one"),"Category"],
    [I18n.t("activerecord.models.item.one"),"Item"]
  ]
  TYPES = [
    {:text => I18n.t('views.forms.percent_off'), :value => 'percent'},
    {:text => I18n.t('views.forms.fixed_amount_off'), :value => 'fixed'}, 
  ]
  validates_presence_of :name
  after_save :refresh_discounts
  after_update :refresh_discounts
  after_destroy :refresh_discounts
  def set_sku
    self.sku = "#{self.name}".gsub(/[^a-zA-Z0-9]+/,'')
  end
  def refresh_discounts
    
  end
  def amount=(a)
    a = a.to_s.gsub(',','.').to_f
    write_attribute(:amount,a)
  end
  def types_display
    TYPES.each do |type|
      return type[:text] if self.amount_type == type[:value]
    end
    return self.amount_type
  end
  def item
    if self.applies_to == 'Item' then
      return Item.scopied.find_by_sku(self.item_sku)
    end
  end
    # WTF? I have no idea what this is even doing here...
  # REMOVE ME SOON
  def simulate(item)
    price = item.base_price
    damount = 0
    if self.amount_type == 'percent' then
          d = self.amount / 100
          damount += (price * d)
    else
      damount += self.amount
    end
    item.base_price = price - damount
    return item
  end
  
end
