# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

module SalorScope
  # Ruby will pas in the Class variable when it called .included
  # which is a kind of event
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
  
    
    klass.scope(:by_keywords, lambda do |keywords|
      conds = []
      vals = []
      return nil if keywords.blank?
      
      words = keywords.gsub /[^-0-9a-zA-Z ]/, ""
      # Support searching orders by date and time
      # we need to convert those times to utc for searching, becuase
      # that is how we are storing the dates and times in the database
      
      dates = SalorBase.convert_times_to_utc(keywords.scan(/(\d+\-\d+\-\d+) (\d+\-\d+\-\d+)/))
      dates2 = SalorBase.convert_times_to_utc(keywords.scan(/(\d+-\d+-\d+ \d+:\d+:\d+) (\d+-\d+-\d+ \d+:\d+:\d+)/))
      if klass == Order then

        if not dates.empty? or not dates2.empty? then

          conds << "completed_at between '#{dates[0][0]}' and '#{dates[0][1]}'" if not dates.empty?
          conds << "completed_at between '#{dates2[0][0]}' and '#{dates2[0][1]}'" if not dates2.empty?
        else
          conds << "nr = '#{words}' OR qnr = '#{words}' OR tag LIKE '#{words}%'"
        end
        return klass.where(conds.join())
      end
                                      
      conds << "id = '#{words}'"
      if klass.column_names.include?('name')
                                      
        if words =~ /([\w\*]+) (\d{1,5}[\.\,]\d{1,2})/ and klass.column_names.include?('price_cents')
          parts = words.match(/([\w\*]+) (\d{1,5}[\.\,]\d{1,2})/)
          price_cents = (SalorBase.string_to_float(parts[2].gsub(',','.'), :locale => 'en-us') * 100).to_i
          if parts[1] == '*'
            conds << "`price_cents` > #{(price_cents - 500).to_i} AND `price_cents` < #{(price_cents + 500).to_i}"
          else
            conds << "`name` LIKE '%#{parts[1].split(" ").join("%")}%' AND `price_cents` > #{(price_cents - 500).to_i} AND `price_cents` < #{(price_cents + 500).to_i}"
          end
        else
          words = words.split(" ").join("%")
          conds << "`name` LIKE '%#{words}%'"
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
    end)
    
    
    rescue
    end
    
  end
end
