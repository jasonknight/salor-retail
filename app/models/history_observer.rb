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
class HistoryObserver < ActiveRecord::Observer
  include SalorBase
  observe :order_item, :item, :order, :employee, :customer, :loyalty_card
  def after_update(object)
    if object.class == Order then
      #order rules go here
      object.changes.keys.each do |k|
        if [:hidden, :total, :paid].include? k.to_sym then
          History.record('order_edit_' + k,object,2)
        end
      end
    elsif object.class == OrderItem then
      object.changes.keys.each do |k|
        if [:price, :hidden, :total].include? k.to_sym then
          History.record('order_item_edit_' + k,object,3)
        end
      end
    elsif object.class == LoyaltyCard then
      # i.e. we should only track point changes that are very large
      # FIXME this should be relative to the stores setting in some way
      if object.changes['points'] and (object.changes['points'][1].to_i - object.changes['points'][0].to_i) > 200 then
        History.record("loyalty_card_points",object,4)
      end
    else
      object.changes.keys.each do |k|
        if [:base_price, :price, :hidden, :value, :sku, :name, :amount].include? k.to_sym then
          History.record("#{object.class.to_s.downcase}_edit_#{k}",object,5)
        end
      end
    end 
  end
  def before_destroy(object)
    sen = 2
    if [:order,:order_item,:employee].include? object.class.to_sym then
      sen = 1
    end
    History.record("destroy_#{object.class.to_s}",object,sen)
  end
end

