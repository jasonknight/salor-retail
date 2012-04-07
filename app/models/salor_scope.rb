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
module SalorScope
  def self.included(klass)
    begin
      inst = klass.new
      klass.scope(:by_vendor, lambda { |*args|
         if inst.respond_to? :vendor_id and not inst.class == TaxProfile
           return {:conditions => ["vendor_id = ? ", GlobalData.salor_user.get_meta.vendor_id]} if GlobalData.salor_user
         end
      })
      klass.scope(:visible, lambda { |*args|
         if inst.respond_to? :hidden
           return {:conditions => "`#{ inst.class.table_name}`.`hidden` = 0 or `#{ inst.class.table_name}`.`hidden` is null"}
         end
               })
      klass.scope(:invisible, lambda { |*args|
         if inst.respond_to? :hidden
           return {:conditions => "`#{ inst.class.table_name }`.`hidden` = 1"}
         end
      })
      klass.scope(:by_user, lambda { |*args|
          if inst.class == Order and 
             GlobalData.salor_user and 
             GlobalData.salor_user.is_employee? and
             not GlobalData.salor_user.can(:head_cashier) and
             not GlobalData.salor_user.can(:edit_orders) then
             return {:conditions => 'employee_id = ' + GlobalData.salor_user.id.to_s}
          end
          if inst.respond_to? :user_id
            return {:conditions => 'user_id = ' + GlobalData.salor_user.get_owner.id.to_s}
         end
      })
      klass.scope(:by_keywords, lambda {|*args|
         conds = []
         vals = []
         words = GlobalData.params.keywords if GlobalData.params
         return if words.nil? or words.blank?
         conds << "id = '#{words}'"
         if inst.respond_to? :name then
           if words =~ /([\w\*]+) (\d{1,5}[\.\,]\d{1,2})/ and inst.respond_to? :base_price then
             parts = words.match(/([\w\*]+) (\d{1,5}[\.\,]\d{1,2})/)
             price = SalorBase.string_to_float(parts[2]) 
             if parts[1] == '*' then
               conds << "base_price > #{(price - 5).to_i} and base_price < #{(price + 5).to_i}"
             else
               conds << "name LIKE '%#{parts[1].split(" ").join("%")}%' and base_price > #{(price - 5).to_i} and base_price < #{(price + 5).to_i}"
             end
           else
             words = words.split(" ").join("%")
             conds << "name LIKE '%#{words}%'"
           end
         end
         if inst.respond_to? :first_name then
           if words.include? " " then
             parts = words.split(" ")
             conds << "first_name LIKE '%#{parts[0]}%'"
           else
             conds << "first_name LIKE '%#{words}%'"
           end
         end
         if inst.respond_to? :last_name then
           if words.include? " " then
             parts = words.split(" ")
             conds << "last_name LIKE '%#{parts[1]}%'"
           else
             conds << "last_name LIKE '%#{words}%'"
           end
         end
         if inst.respond_to? :sku then
           conds << "sku LIKE '#{words}%'"
         end
         if inst.respond_to? :username then
           conds << "username LIKE '#{words}%'"
         end
         if inst.respond_to? :email then
           conds << "email LIKE '#{words}%'"
         end
        if inst.respond_to? :tag then
           conds << "tag LIKE '%#{words}%'"
         end

         return {:conditions => conds.join(" OR ")}
      })
      klass.scope(:scopied, lambda { |*args|
          klass.send(:by_keywords).visible.by_vendor.by_user
      } )
      klass.scope(:all_seeing, lambda { |*args|
          klass.send(:by_keywords).by_vendor.by_user
      } )
      
      rescue Exception => e
        # puts "Something bad happend..."
      end
  end
end
