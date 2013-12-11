# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class Report
  def self.dump_all(vendor, from, to, device)

    tfrom = from.strftime("%Y%m%d")
    tto = to.strftime("%Y%m%d")
    
    order_items = vendor.order_items.where(:created_at => from..to)
    File.open("#{device}/SalorRetailOrderItems#{tfrom}-#{tto}.csv","w") do |f|
      attributes = "id;quantity;item_id;order_id;created_at;updated_at;price_cents"
      f.write("#{attributes}\n")
      f.write Report.to_csv(order_items, OrderItem, attributes)
    end
    
  end
  
  def self.to_csv(objects, klass, attributes)
    attrs = attributes.split(";")
    formatstring = ""
    attrs.each do |a|
      #puts "ATTR #{ klass.to_s}: #{ a }"
      cls = klass.columns_hash[a].type if klass.columns_hash[a]
      case cls
      when :integer
        formatstring += "\"%i\";"
      when :datetime, :string, :boolean, :text
        formatstring += "\"%s\";"
      when :float
        formatstring += "\"%.2f\";"
      else
        formatstring += "\"%s\";"
      end
    end
    lines = []
    objects.each do |item|
      values = []
      attrs.size.times do |j|
        val = attrs[j].split('.').inject(item) do |klass, method|
          klass.send(method) unless klass.nil?
        end
        #val = 0 if val.nil?
        values << val
      end
      lines << sprintf(formatstring, *values)
    end
    
    return lines.join("\n")
  end
  
  
end
