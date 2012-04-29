# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

module SalorScope
  def self.included(klass)
    begin
      # {START}
      inst = klass.new
      klass.scope(:by_vendor, lambda { |*args|
         if inst.respond_to? :vendor_id and not inst.class == TaxProfile
           return {:conditions => ["vendor_id = ? ", GlobalData.salor_user.get_meta.vendor_id]} if GlobalData.salor_user
         end
      })
      klass.scope(:visible, lambda { |*args|
         if inst.respond_to? :hidden
           return { :conditions => "`#{ inst.class.table_name}`.`hidden` = 0 or `#{ inst.class.table_name}`.`hidden` is null"}
         end
               })
      klass.scope(:invisible, lambda { |*args|
         if inst.respond_to? :hidden
           return {:conditions => "`#{ inst.class.table_name }`.`hidden` = 1"}
         end
      })
      klass.scope( :by_user , lambda { |*args|
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
      klass.scope( :by_keywords , lambda {|*args|
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
      # {END}
  end
end
