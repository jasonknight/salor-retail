# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

module SalorScope
  
  def self.included(klass)
       
    
    begin


    if klass.column_names.include? 'hidden'
      klass.scope(:visible, lambda {
                                    klass.where("`#{klass.table_name}`.`hidden` = FALSE OR `#{klass.table_name}`.`hidden` IS NULL")
                                   })
    end
    
    if klass.column_names.include? 'paid'
      klass.scope(:paid, lambda {
                                    klass.where("`#{klass.table_name}`.`paid` IS TRUE")
                                   })
    end
    
    if klass.column_names.include? 'completed_at'
      klass.scope(:completed, lambda {
                                    klass.where("`#{klass.table_name}`.`completed_at` IS NOT NULL")
                                   })
    end
  
    
    klass.scope(:by_keywords, lambda { |words|
      conds = []
      vals = []
      return nil if words.blank?
                                      
      if klass == Order then
        conds << "nr = '#{words}' or qnr = '#{words}' or tag LIKE '#{words}%'"  
        return klass.where(conds.join())
      end
                                      
      conds << "id = '#{words}'"
      if klass.column_names.include?('name')
                                      
        if words =~ /([\w\*]+) (\d{1,5}[\.\,]\d{1,2})/ and klass.column_names.include?('base_price')
          parts = words.match(/([\w\*]+) (\d{1,5}[\.\,]\d{1,2})/)
          price = SalorBase.string_to_float(parts[2]) 
          if parts[1] == '*'
            conds << "base_price > #{(price - 5).to_i} and base_price < #{(price + 5).to_i}"
          else
            conds << "name LIKE '%#{parts[1].split(" ").join("%")}%' and base_price > #{(price - 5).to_i} and base_price < #{(price + 5).to_i}"
          end
        else
          words = words.split(" ").join("%")
          conds << "name LIKE '%#{words}%'"
        end
                                      
      end

      if klass.column_names.include?('first_name')
        if words.include? " "
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
    end
    
  end
end
