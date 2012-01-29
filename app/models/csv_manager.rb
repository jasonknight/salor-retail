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
require "kcsv.rb"
class CsvManager
  @@separator = "\t"
  attr_accessor :items, :successes, :errors,:order
  def initialize(file, separator = "\t")
    @items = []
    @errors = []
    @successes = []
    @order = "id desc"
    @output = {}
    @@separator = separator if not separator.nil?
    return if file.nil?
    csv = Kcsv.new(file, {:header => true, :separator => @@separator})
   
    models = {}
    csv.to_a.each do |row|
      st = []
      row.each do |k,v|
        st << "#{k}=#{v}"
      end
      st = st.join("&")
      ## puts st
      hash1 = {}
      hash2 = {}
      array1 = []
      array2 = []
      resulthash = {}
      count = 0
      count2 = 0
      keynum2 = 0
      main = 'base'
      h3main = 'base'
      #extremely crazy stuff, but it sorta works so oh well... What I'd give for a parse_str function like PHP
      st.scan(/([\w]+)(\[|=)(.*?)(?=(&[\w]+\[|&[\w]+=|$))/) {
        var = $1 << $2 << $3  
        case var
          when /^([\w]+)\[(.*?)\]\[(\d+)\]\[(.*?)\]=(.*?)$/ then
            count2 += 1
             h3main = $2
             keynum2 = $2 << count2.to_s
             i = $3.to_i
             array1[i] = {} if array1[i].class != Hash
             array1[i].update({$4 => process_value($5)})
             hash2.update(keynum2 => array1)
          when /^([\w]+)\[(.*?)\]\[\]\[(.*?)\]=(.*?)$/ then
             count2 += 1
             h3main = $2
             keynum2 = $2 << count2.to_s
             i = count2
             array2[i] = {} if array2[i].class != Hash
             array2[i].update({$3 => process_value($4)})
             hash2.update(keynum2 => array2)
          when /^([\w]+)\[(.*?)\]=(.*?)$/ then 
             main = $1
             count += 1
             keynum = $1 << count.to_s
             hash1.update(keynum => {$2 => process_value($3)})
          when /^(a)=(.*?)$/ then 
            resulthash.update($1 => $2)
        end
      }
      ## puts hash1.inspect
      hashx = {}
      hash1.each_pair {|k,v| hashx.update(v)}
      #hash1.each_pair {|k,v| resulthash.update(main => v) }
      resulthash[main] = hashx
      if not hash2.empty? then
        if not resulthash[h3main].class == Hash then
          resulthash[main][h3main] = {}
        end
        hash2.each_pair{ |k,v| 
          if v.class == Array then
            resulthash[main][h3main] = v
          else
            resulthash[main][h3main].update(v)
          end
        }
      end
      @items << resulthash
    end #end csv.to_a
  end
  
  def manual_set(nums)
    @items = []
    nums.each do |n|
      @items.push({"Item" => {"sku" => n.chomp}})
    end
  end
  def before_add_hash(model,hash)
    return hash
  end
  def before_edit_hash(model,hash)
    return hash
  end
  def before_delete_hash(model,hash)
    return hash
  end
  def route(params_hash)
    case params_hash[:download_type]
      when 'code' then
        return self.download_by_field('Item','sku IS NOT NULL')
      when 'zeroed' then
        return self.download_by_field('Item','quantity > 0')
      when 'unstocked' then
        return self.download_by_field('ShipmentItem','in_stock IS FALSE')
      when 'category' then
        return self.download_by_field('Item',"category_id = #{params_hash[:category_id]}")
      when 'location' then
        return self.download_by_field('Item',"location_id = #{params_hash[:location_id]}")
      when 'orders_completed' then
        return self.download_by_field('Orders','paid IS TRUE')
      when 'orders_refunded' then
        return self.download_by_field('Orders','refunded IS TRUE')
      when 'order_items' then
        return self.download_by_field('OrderItem','refunded IS FALSE and paid IS TRUE')
      when 'order_items_refunded' then
        return self.download_by_field('OrderItem','refunded IS TRUE','model.order.paid == true')
   end
   return 'failed'
  end
  
  def get_record(model)
    record = nil
    if model.class = Item then
      record = model.find_by_sku(attributes_hash['sku']) if attributes_hash['sku']
    else
      record = model.find_by_id(attributes_hash['id']) if attributes_hash['id']
      if not record then
        record = model.find_by_name(attributes_hash['name']) if attributes_hash['name']
      end
    end
    return record
  end
  
  def add
    i = 1
    @items.each do |hash|
      hash.each { |modelname,attributes_hash|
        record,variant = nil,nil
        model = modelname.constantize
        attributes_hash = before_add_hash(model,attributes_hash)
        if not model then
          @errors << I18n.t("system.errors.no_class", :model => modelname,:i => i)
          i = i + 1
          next
        end
        record = get_record(model)
  
        if record.nil? and variant.nil? and not attributes_hash.nil? then
          newrecord = model.new(attributes_hash)
          if model == Item then
            if newrecord.sku.blank? then
              newrecord.sku = attributes_hash['sku']
            end
          end
          if newrecord.save then
            @successes << I18n.t("views.notice.model_create", :model => modelname)
          else
            @errors << I18n.t("system.errors.csv_item_failed", :id => attributes_hash['sku'], :i => i)
          end
        else
          @errors << I18n.t("system.errors.csv_item_exists", :sku => attributes_hash['sku'])
        end
        i = i + 1
      }
    end
    return {:successes => @successes, :errors => @errors}
  end
  
  
  def edit
    i = 1
    @successes << I18n.t("views.notice.csv_edit_starting")
    @items.each do |hash|
      hash.each { |modelname,attributes_hash|
        # puts "#{modelname} - #{attributes_hash['sku']}"
        begin
          model = modelname.constantize
          attributes_hash = before_edit_hash(model,attributes_hash)
          if not model then
            @errors << I18n.t("system.errors.no_class", :model => modelname,:i => i)
            i = i + 1
            next
          end
          record = get_record
            
          if record and attributes_hash then
            begin
              if record.update_attributes(attributes_hash) then
                @successes << I18n.t("views.notice.model_edit", :model => modelname)
              else
                @errors << I18n.t("views.notice.model_edit", :model => modelname)
              end
            rescue
              @errors << attributes_hash['sku'].to_s + $!
            end
          else
            @errors << "#{attributes_hash['sku']}  #{modelname} #{i} does not exist yet. Not edited."
          end
  
          i = i + 1
        rescue
          @errors << $!
        end
      }
    end
    return {:successes => @successes, :errors => @errors}
  end
  
  
  def delete
    i = 0
    @items.each do |hash|
      hash.each { |modelname,attributes_hash|
      
        model = modelname.constantize
        attributes_hash = before_delete_hash(model,attributes_hash)
        if not model then
          errors << I18n.t("system.errors.no_class", :model => modelname,:i => i)
          i = i + 1
          next
        end
        
        @errors << "An id or an sku must be specified for each object! at line #{i}" if not attributes_hash['id'] and not attributes_hash['sku']
        
        record = get_record(model)
        
        if record then
          record.destroy
          @successes << I18n.t("views.notice.model_edit", :model => modelname)
        else
          @errors << "Could not find object by ID or SKU at line #{i} #{attributes_hash['sku']}"
        end
        i = i + 1
      }
    end
    return {:successes => @successes, :errors => @errors}
  end
  
  
  def process_value(v)
    #helps to set an array of values...
    if v.class == String then
      if v.include? "||" then
        v = v.split("||")
      end
    end
    return v
  end
  
  def get_model_as_csv(model) #should be an instance of model, not just the name.
    values = []
    if model.respond_to?('to_csv') then
      values = model.to_csv
    else
      model.class.content_columns.each {|k|
        values << model.send(k.name)
      }
    end
    return values.join(@@separator)
  end
  
  def get_headers_for(classname)
    model = classname.constantize
    cname = classname
    if model.respond_to?('to_csv_headers') then #means it must be a static method
      headers = model.to_csv_headers
    else
      headers = []
      model.content_columns.each {|k|
        headers << "#{cname}[#{k.name}]"
      }
    end
    return headers.join(@@separator)
  end
  
  def collect_items_by_field(field,modelname='Item')
    codes = []
    @items.each do |line|
      if modelname and line[modelname] then
        codes << line[modelname][field]
      elsif line[field] then
        codes << line[field]
      end
    end
    
    return codes
  end
  
  # downloading
  
  def download_by_field(classname,conditions, exclusion_code=nil)
    cls = classname.constantize
    lines = [get_headers_for(classname)]
    models = cls.where(conditions).order(@order)
    if models.any? then
      models.each {|model|
        if exclusion_code then
          v = eval(exclusion_code)
          if not v then
            next
          end
        end
        lines << get_model_as_csv(model)
      }
    end
    return lines.join("\n")
  end #def download_by_field(classname,field,value)
end

