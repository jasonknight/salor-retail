# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

module SalorScope
  def self.included(klass)
    begin
    if klass.column_names.include? 'vendor_id'
      klass.scope(:by_vendor, lambda { klass.where("`#{klass.table_name}`.vendor_id = #{@current_user.vendor_id}") if @current_user })
    end

    if klass.column_names.include? 'hidden'
      klass.scope(:visible, lambda { klass.where("`#{klass.table_name}`.hidden = FALSE OR `#{klass.table_name}`.hidden IS NULL OR `#{klass.table_name}`.hidden = 0") })
      klass.scope(:invisible, lambda { klass.where("`#{klass.table_name}`.hidden = TRUE OR `#{klass.table_name}`.hidden = 1") })
    end
  
    if klass.class == Order
      klass.scope(:by_user , lambda { klass.where("`#{klass.table_name}`.user_id = #{@current_user.id}") if @current_user and $User.is_user? and not $User.can(:head_cashier) and not $User.can(:edit_orders) })
    elsif klass.column_names.include?('user_id') and [TaxProfile,Shipper,ShipmentType,TransactionTag].include?(klass.class) == false
      klass.scope(:by_user , lambda { klass.where(:user_id => @current_user.get_user.id.to_s) if @current_user })
    else
      klass.scope(:by_user, lambda {})
    end
    
    klass.scope(:scopied, lambda { klass.by_keywords.visible.by_vendor.by_user })
    
    klass.scope(:all_seeing, lambda { klass.by_keywords.by_vendor.by_user })
    
    klass.scope(:by_keywords , lambda {
      conds = []
      vals = []
      # TODO: Get rid of GlobalData
      words = $Params[:keywords] if $Params
      return if words.nil? or words.blank?
      if klass == Order then
        conds << "nr = '#{words}' or qnr = '#{words}' or tag LIKE '#{words}%'"  
        return klass.where(conds.join())
      end
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
          conds << "first_name LIKE '#{parts[0]}%'"
        else
          conds << "first_name LIKE '#{words}%'"
        end
      end
      if klass.column_names.include?('last_name') then
        if words.include? " " then
          parts = words.split(" ")
          conds << "last_name LIKE '#{parts[1]}%'"
        else
          conds << "last_name LIKE '#{words}%'"
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
      klass.where(conds.join(" OR "))
    })
    rescue
      puts "Error in SalorScope"
    end
  end
end
