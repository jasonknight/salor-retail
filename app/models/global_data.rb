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
class GlobalData
  # This is a Locator/Broker class for global data that
  # Needs to be accessible everywhere!
  @@attrs = nil
  def self.cash_drawer
    p = 'NotSet'
    if self.cash_register and self.cash_register.cash_drawer_path then
      p = '' if self.cash_register.cash_drawer_path.to_s == '0'
      p =  self.cash_register.cash_drawer_path
    else
      p = self.conf.cash_drawer
    end
    return p
  end
  def self.refresh
    @@attrs = nil
  end
  def self.reload(sym)
    sym = sym.to_s
    @@attrs[sym].reload if @@attrs[sym]
  end
  def refresh
    @@attrs = nil
  end
  def self.method_missing(sym, *args, &block)
    @@attrs ||= {}
    osym = sym
    sym = sym.to_s
    if sym.include? "=" then
      @@attrs[sym.gsub('=','')] = args.first
    else
      if @@attrs[sym].class == Hash then
        return ValueProxy.new(@@attrs[sym])
      else
        if @@attrs[sym] then
          return @@attrs[sym]
        else
          #k it wasn't found, so let's find it and set it
          if osym == :vendors then
            self.vendors = self.salor_user.get_vendors(nil)
            return self.vendors
          elsif osym == :categories then
            self.categories = self.salor_user.get_all_categories
            return self.categories
          elsif osym == :conf then
            if self.params.vendor_id then
              self.conf = SalorConfiguration.find_by_vendor_id(self.params.vendor_id)
              return self.conf
            end
            return nil
          elsif osym == :locations then
            self.locations = self.salor_user.get_locations
            return self.locations
          elsif osym == :item_types then
            self.item_types = ItemType.all
            return self.item_types
          elsif osym == :tax_profiles then
            self.tax_profiles = self.salor_user.get_tax_profiles
            return self.tax_profiles
          end
        end #end if @@attrs[sym] then
      end
    end
  end
end
