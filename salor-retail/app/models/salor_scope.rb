# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

module SalorScope
  def self.included(klass)
    klass.scope(:by_vendor, lambda { |model|
      if model.respond_to?(:vendor_id) and not model.vendor_id.nil?
        klass.where(:vendor_id => $User.vendor_id) if $User
      end
    })

    if klass.column_names.include? 'hidden'
      klass.scope(:visible, lambda { klass.where('hidden = FALSE OR hidden IS NULL') })
      klass.scope(:invisible, lambda { klass.where('hidden = TRUE OR hidden = 1') })
    end
  
    klass.scope( :by_user , lambda { |model|
      if model.class == Order and $User and $User.is_employee? and not $User.can(:head_cashier) and not $User.can(:edit_orders)
        klass.where(:employee_id => $User.id.to_s)
      elsif model.respond_to? :user_id and [TaxProfile,Shipper,ShipmentType].include?(model.class) == false
        klass.where(:user_id => $User.get_owner.id.to_s)
      end
    })
    
    klass.scope(:scopied, lambda { |model|
      klass.by_keywords.visible.by_vendor.by_user
    })
    
    klass.scope(:all_seeing, lambda { |model|
      klass.by_keywords.by_vendor.by_user
    })
    
    
    
    klass.scope(:by_keywords , lambda {|model|
      conds = []
      vals = []
      words = GlobalData.params.keywords if GlobalData.params
      return if words.nil? or words.blank?
      conds << "id = '#{words}'"
      if model.respond_to? :name then
        if words =~ /([\w\*]+) (\d{1,5}[\.\,]\d{1,2})/ and model.respond_to? :base_price then
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
      if model.respond_to? :first_name then
        if words.include? " " then
          parts = words.split(" ")
          conds << "first_name LIKE '%#{parts[0]}%'"
        else
          conds << "first_name LIKE '%#{words}%'"
        end
      end
      if model.respond_to? :last_name then
        if words.include? " " then
          parts = words.split(" ")
          conds << "last_name LIKE '%#{parts[1]}%'"
        else
          conds << "last_name LIKE '%#{words}%'"
        end
      end
      if model.respond_to? :sku then
        conds << "sku LIKE '#{words}%'"
      end
      if model.respond_to? :username then
        conds << "username LIKE '#{words}%'"
      end
      if model.respond_to? :email then
        conds << "email LIKE '#{words}%'"
      end
      if model.respond_to? :tag then
        conds << "tag LIKE '%#{words}%'"
      end
      return {:conditions => conds.join(" OR ")}
    })
  end
end
