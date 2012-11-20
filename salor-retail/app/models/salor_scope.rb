# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

module SalorScope
  def self.included(klass)
    begin
    if klass.column_names.include? 'vendor_id'
      klass.scope(:by_vendor, lambda { klass.where(:vendor_id => $User.vendor_id) if $User })
    end

    if klass.column_names.include? 'hidden'
      klass.scope(:visible, lambda { klass.where('hidden = FALSE OR hidden IS NULL OR hidden = 0') })
      klass.scope(:invisible, lambda { klass.where('hidden = TRUE OR hidden = 1') })
    end
  
    if klass.class == Order
      klass.scope(:by_user , lambda { klass.where(:employee_id => $User.id.to_s) if $User and $User.is_employee? and not $User.can(:head_cashier) and not $User.can(:edit_orders) })
    elsif klass.column_names.include?('user_id') and [TaxProfile,Shipper,ShipmentType,TransactionTag].include?(klass.class) == false
      klass.scope(:by_user , lambda { klass.where(:user_id => $User.get_owner.id.to_s) if $User })
    else
      klass.scope(:by_user, lambda {})
    end
    
    klass.scope(:scopied, lambda { klass.by_keywords.visible.by_vendor.by_user })
    
    klass.scope(:all_seeing, lambda { klass.by_keywords.by_vendor.by_user })
    
    klass.scope(:by_keywords , lambda {
      conds = []
      vals = []
      # TODO: Get rid of GlobalData
      words = GlobalData.params.keywords if GlobalData.params
      return if words.nil? or words.blank?
      conds << "id = '#{words}'"
      if klass.column_names.include?('name') then
        if words =~ /([\w\*]+) (\d{1,5}[\.\,]\d{1,2})/ and klass.column_names.include?('base_price') then
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
      if klass.column_names.include?('first_name') then
        if words.include? " " then
          parts = words.split(" ")
          conds << "first_name LIKE '%#{parts[0]}%'"
        else
          conds << "first_name LIKE '%#{words}%'"
        end
      end
      if klass.column_names.include?('last_name') then
        if words.include? " " then
          parts = words.split(" ")
          conds << "last_name LIKE '%#{parts[1]}%'"
        else
          conds << "last_name LIKE '%#{words}%'"
        end
      end
      if klass.column_names.include?('sku') then
        conds << "sku LIKE '#{words}%'"
      end
      if klass.column_names.include?('username') then
        conds << "username LIKE '#{words}%'"
      end
      if klass.column_names.include?('email') then
        conds << "email LIKE '#{words}%'"
      end
      if klass.column_names.include?('tag') then
        conds << "tag LIKE '%#{words}%'"
      end
      klass.where(conds.join(" OR "))
    })
    rescue
      puts "Error in SalorScope"
    end
  end
end
