# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.


class FileUpload
  include SalorBase
  
  attr_accessor :i, :shipper, :updated_items, :created_items, :created_categories, :updated_item_ids, :created_item_ids, :messages
  
  def initialize(shipper, data)
    @format = shipper.import_format
    @data = data
    @lines = data.split("\n")
    @shipper = shipper
    @vendor = @shipper.vendor
    @company = @shipper.company
    @item_type = @vendor.item_types.visible.where(:behavior => "normal").first
    
    @i = 0
    @updated_items = 0
    @created_items = 0
    @created_categories = 0
    
    @updated_item_ids = []
    @created_item_ids = []
    @messages = []
    log_action "for #{ @shipper.name }: initialized. Line count is #{ @lines.count }"
  end
  
  def crunch
    log_action "crunch for #{ @shipper.name }: calling self.#{ @format }"
    self.send @format
  end

  def type1
    log_action "type1 for #{ @shipper.name }: called"
  
    if @lines.first.include? '#' then
      log_action "type1 for #{ @shipper.name }: delimiter is hash"
      delim = '#'
    elsif @lines.first.include? ';'
      log_action "type1 for #{ @shipper.name }: delimiter is semicolon"
      delim = ';'
    else
      raise "Could not detect delimiter in type 1 file: " + @lines.first
    end
    
    @lines.each do |row|
      @i += 1
      next if @i == 1 # skip headers
      columns = row.split(delim)

      shipper_sku = columns[0].strip.gsub(/[^0-9a-zA-Z]/,'')

      name = columns[1].strip
      longname = columns[2].strip.gsub(/\s+/, " ")
      name.encode!('UTF-8', :invalid => :replace, :undef => :replace, :replace => "?")
      longname.encode!('UTF-8', :invalid => :replace, :undef => :replace, :replace => "?")

      packaging_unit_pack = columns[12].to_i # Menge_PA
      packaging_unit_carton = columns[11].to_i # Menge_GB
      packaging_unit_container = columns[13].to_i # Menge_BEH

      base_price = columns[14].to_i
      purchase_price = columns[15].to_i

      #piece price calculation
      base_price_piece = base_price.to_f / packaging_unit_container.to_f
      purchase_price_piece = purchase_price.to_f / packaging_unit_container.to_f

      #pack price calculation
      base_price_pack = base_price_piece.to_f * packaging_unit_pack.to_f
      purchase_price_pack = purchase_price_piece.to_f * packaging_unit_pack.to_f

      #carton price calculation
      base_price_carton = base_price_piece.to_f * packaging_unit_carton.to_f
      purchase_price_carton = purchase_price_piece.to_f * packaging_unit_carton.to_f

      # packaging_unit_modification
      packaging_unit_carton = packaging_unit_carton.to_f / packaging_unit_pack.to_f

      if columns[36]
        tax_profile = @vendor.tax_profiles.visible.find_by_value(columns[36].to_f / 100.0)
      elsif columns[15] == columns[16]
        # since some wholesalers don't offer the tax field, guess depending on the prices
        tax_profile = @vendor.tax_profiles.visible.find_by_value(0)
      else
        # default
        tax_profile = @vendor.tax_profiles.visible.find_by_default(true)
        raise "At least on TaxProfile has to have the default flag enabled" unless tax_profile
      end
      tax_profile_id = tax_profile.id

      category = @vendor.categories.visible.find_by_name(columns[6].strip)
      catname = columns[6].strip
      if category.nil?
        category = Category.new
        category.vendor = @vendor
        category.company = @company
        category.name = catname
        result = category.save
        raise "A category could not be saved because #{ category.errors.messages }" unless result == true
        @created_categories += 1
      end
      category_id = category.id

      # carton
      attributes = {
        :shipper_sku => shipper_sku,
        :name => longname + " Karton",
        :longname => longname + " Karton",
        :shortname => name + " Karton",
        :price_cents => base_price_carton,
        :purchase_price_cents => purchase_price_carton,
        :tax_profile_id => tax_profile_id,
        :category_id => category_id,
        :shipper_id => @shipper.id,
        :vendor_id => @vendor.id,
        :company_id => @company.id,
        :item_type_id => @item_type.id,
        :currency => @vendor.currency,
        :created_by => -102
      }
      sku_carton = columns[8].strip.gsub(/[^0-9a-zA-Z]/,'')
      carton_item = @vendor.items.visible.where( :name => longname + " Karton" ).first if carton_item.blank?
      carton_item = @vendor.items.visible.where( :name => name + " Karton" ).first if carton_item.blank?
      carton_item = @vendor.items.visible.where( :sku => sku_carton ).first if carton_item.blank? and not sku_carton.blank? # second chance to find by sku in case name has changed
      if carton_item
        attributes.merge! :sku => sku_carton unless sku_carton.blank?
        carton_item.attributes = attributes
        result = carton_item.save
        if result == false
          msg = "carton_item #{ carton_item.sku } #{ carton_item.name } could not be saved because #{ carton_item.errors.messages}"
          @messages << msg
          log_action msg, :light_red
        else
          Action.run(@vendor,carton_item,:on_import)
          log_action "[WHOLESALER IMPORT TYPE 1] Updating carton item #{carton_item.name} #{carton_item.sku}"
          @updated_items += 1
          @updated_item_ids << carton_item.id
        end
      else
        sku_carton = 'C' + (1000000000 + rand(9999999999)).to_s[0..12] if sku_carton.blank?
        attributes.merge! :sku => sku_carton
        attributes.merge! :packaging_unit => packaging_unit_carton # only for create
        carton_item = Item.new; carton_item.vendor = @vendor; carton_item.attributes = attributes
        result = carton_item.save
        if result == false
          msg = "carton_item #{ carton_item.sku } #{ carton_item.name } could not be saved because #{ carton_item.errors.messages}"
          @messages << msg
          log_action msg, :light_red
        else
          Action.run(@vendor,carton_item,:on_import)
          log_action "[WHOLESALER IMPORT TYPE 1] Creating carton item #{carton_item.name} #{carton_item.sku}", :light_green
          @created_items += 1
          @created_item_ids << carton_item.id
        end
      end
      
      # pack
      attributes = {
        :shipper_sku => shipper_sku,
        :name => longname + " Packung",
        :longname => longname + " Packung",
        :shortname => name + " Packung",
        :price_cents => base_price_pack,
        :purchase_price_cents => purchase_price_pack,
        :tax_profile_id => tax_profile_id,
        :category_id => category_id,
        :shipper_id => @shipper.id,
        :vendor_id => @vendor.id,
        :company_id => @company.id,
        :item_type_id => @item_type.id,
        :currency => @vendor.currency,
        :created_by => -102
      }
      sku_pack = columns[9].strip.gsub(/[^0-9a-zA-Z]/,'')
      pack_item = @vendor.items.visible.where( :name => longname + " Packung" ).first
      pack_item = @vendor.items.visible.where( :name => name + " Packung").first if pack_item.blank?
      pack_item = @vendor.items.visible.where( :sku => sku_pack ).first if pack_item.blank? and not sku_pack.blank? # second chance to find by sku in case name has changed
      if pack_item
        attributes.merge! :sku => sku_pack unless sku_pack.blank? # SKUs can update!
        pack_item.attributes = attributes
        result = pack_item.save
        if result == false
          msg = "pack_item #{ pack_item.sku } #{ pack_item.name } could not be saved because #{ pack_item.errors.messages}"
          @messages << msg
          log_action msg, :light_red
        else
          Action.run(@vendor,pack_item,:on_import)
          log_action "[WHOLESALER IMPORT TYPE 1] Updating pack item #{pack_item.name} #{pack_item.sku}"
          @updated_items += 1
          @updated_item_ids << pack_item.id
        end
      else
        sku_pack = 'C' + (1000000000 + rand(9999999999)).to_s[0..12] if sku_pack.blank?
        attributes.merge! :sku => sku_pack
        attributes.merge! :packaging_unit => packaging_unit_pack # only for create
        pack_item = Item.new; pack_item.vendor = @vendor; pack_item.attributes = attributes
        result = pack_item.save
        if result == false
          msg = "pack_item #{ pack_item.sku } #{ pack_item.name } could not be saved because #{ pack_item.errors.messages}"
          @messages << msg
          log_action msg, :light_red
        else
          Action.run(@vendor,pack_item,:on_import)
          log_action "[WHOLESALER IMPORT TYPE 1] Creating pack item #{pack_item.name} #{pack_item.sku}", :light_green
          @created_items += 1
          @created_item_ids << pack_item.id
        end
      end
      
      #pack_item.parent = nil
      #Item.where(:child_id => pack_item.id).update_all :child_id => nil
      carton_item.child = pack_item
      result = carton_item.save
      if result == false
        msg = "carton_item #{ carton_item.sku } #{ carton_item.name } could not be assigned the child #{ pack_item.sku } because #{ carton_item.errors.messages }"
        @messages << msg
        log_action msg, :light_red
      end
      
      # piece
      attributes = {
        :shipper_sku => shipper_sku,
        :name => longname + " Stk.",
        :longname => longname + " Stk.",
        :shortname => name + " Stk.",
        :price_cents => base_price_piece,
        :purchase_price_cents => purchase_price_piece,
        :tax_profile_id => tax_profile_id,
        :category_id => category_id,
        :shipper_id => @shipper.id,
        :vendor_id => @vendor.id,
        :company_id => @company.id,
        :item_type_id => @item_type.id,
        :currency => @vendor.currency,
        :created_by => -102
      }
      sku_piece = columns[19].strip.gsub(/[^0-9a-zA-Z]/,'') if columns[19]
      piece_item = @vendor.items.visible.where( :name => longname + " Stk." ).first
      piece_item = @vendor.items.visible.where( :name => name + " Stk.").first if piece_item.blank?
      piece_item = @vendor.items.visible.where( :sku => sku_piece ).first if piece_item.blank? and not sku_piece.blank?
      if piece_item
        attributes.merge! :sku => sku_piece unless sku_piece.blank?
        piece_item.attributes = attributes
        result = piece_item.save
        if result == false
          msg = "piece_item #{ piece_item.sku } #{ piece_item.name } could not be saved because #{ piece_item.errors.messages}"
          @messages << msg
          log_action msg, :light_red
        else
          Action.run(@vendor,piece_item,:on_import)
          log_action "[WHOLESALER IMPORT TYPE 1] Updating piece item #{piece_item.name} #{piece_item.sku}"
          @updated_items += 1
          @updated_item_ids << piece_item.id
        end
      else
        sku_piece = 'C' + (1000000000 + rand(9999999999)).to_s[0..12] if sku_piece.blank?
        attributes.merge! :sku => sku_piece
        attributes.merge! :packaging_unit => 1 # only for create
        piece_item = Item.new; piece_item.vendor = @vendor; piece_item.attributes = attributes
        result = piece_item.save
        if result == false
          msg = "piece_item #{ piece_item.sku } #{ piece_item.name } could not be saved because #{ piece_item.errors.messages}"
          @messages << msg
          log_action msg, :light_red
        else
          Action.run(@vendor,piece_item,:on_import)
          log_action "[WHOLESALER IMPORT TYPE 1] Creating piece item #{piece_item.name} #{piece_item.sku}", :light_green
          @created_items += 1
          @created_item_ids << piece_item.id
        end
      end
      #debugger if longname.include? "La Aurora Princ Natural 25"
      #piece_item.parent = nil
      #Item.where(:child_id => piece_item.id).update_all :child_id => nil
      pack_item.child = piece_item
      result = pack_item.save
      if result == false
        msg = "pack_item #{ pack_item.sku } #{ pack_item.name } could not be assigned the child #{ piece_item.sku } because #{ pack_item.errors.messages }"
        @messages << msg
        log_action msg, :light_red
      end

    end
  end

  def type2
    log_action "type2 for #{ @shipper.name }: called"
    
    if @lines[0].include?('#') or @lines[1].include?('#') then
      log_action "type2 for #{ @shipper.name }: delimiter is hash"
      delim = '#'
    elsif @lines[0].include?(';') or @lines[1].include?(';')
      log_action "type2 for #{ @shipper.name }: delimiter is semicolon"
      delim = ';'
    else
      raise "Could not detect delimiter in type 2 file: " + @lines.first
    end
    
    @lines.each do |row|
      @i += 1
      next if @i == 1 # skip headers
      next if row.strip.blank?
      columns = row.chomp.split(delim)

      shipper_sku = columns[0].strip.gsub(/[^0-9a-zA-Z]/,'')

      name = columns[1].strip
      longname = columns[2].strip.gsub(/\s+/, " ")
      name.encode!('UTF-8', :invalid => :replace, :undef => :replace, :replace => "?")
      longname.encode!('UTF-8', :invalid => :replace, :undef => :replace, :replace => "?")

      packaging_unit_pack = columns[12].gsub(',','.').to_f # MENGE_PA
      packaging_unit_pack = 1 if packaging_unit_pack.zero?
      packaging_unit_carton = columns[11].gsub(',','.').to_f # MENGE_GB
      packaging_unit_carton = 1 if packaging_unit_carton.zero?
      packaging_unit_container = columns[13].gsub(',','.').to_f # MENGE_BEH
      packaging_unit_container = 1 if packaging_unit_container.zero?

      base_price = columns[14].gsub(',','.').to_f / 100
      purchase_price = columns[15].gsub(',','.').to_f / 100
      
      # piece price calculation
      base_price_piece = base_price.to_f / packaging_unit_container.to_f
      purchase_price_piece = purchase_price.to_f / packaging_unit_container.to_f

      # pack price calculation
      base_price_pack =  base_price_piece.to_f * packaging_unit_pack.to_f
      purchase_price_pack =  purchase_price_piece.to_f * packaging_unit_pack.to_f

      # carton price calculation
      base_price_carton = base_price_piece.to_f * packaging_unit_carton.to_f
      purchase_price_carton = purchase_price_piece.to_f * packaging_unit_carton.to_f

      # packaging_unit_modification
      packaging_unit_carton = packaging_unit_carton.to_f / packaging_unit_pack.to_f

      if columns[36]
        tax_profile = @vendor.tax_profiles.visible.find_by_value(columns[36].to_f / 100)
      elsif columns[15] == columns[16]
        # since some wholesalers don't offer the tax field, guess depending on the prices
        tax_profile = @vendor.tax_profiles.visible.find_by_value(0)
      else
        # default
        tax_profile = @vendor.tax_profiles.visible.find_by_value(20)
      end
      tax_profile_id = tax_profile.id

      category = @vendor.categories.visible.find_by_name(columns[6].strip)
      catname = columns[6].strip
      catname = columns[6].strip
      if category.nil?
        category = Category.new
        category.vendor = @vendor
        category.company = @company
        category.name = catname
        result = category.save
        raise "A category could not be saved because #{ category.errors.messages }" unless result == true
        @created_categories += 1
      end
      category_id = category.id

      
      
      # carton
      attributes = {
        :shipper_sku => shipper_sku,
        :name => name + " Karton",
        :longname => longname + " Karton",
        :shortname => name + " Karton",
        :base_price => base_price_carton,
        :purchase_price => purchase_price_carton,
        :tax_profile_id => tax_profile_id,
        :category_id => category_id,
        :shipper_id => @shipper.id,
        :vendor_id => @vendor.id,
        :company_id => @company.id,
        :item_type_id => @item_type.id,
        :currency => @vendor.currency,
        :created_by => -102
      }
      sku_carton = columns[8].strip.gsub(/[^0-9a-zA-Z]/,'') # EAN_GB
      carton_item = @vendor.items.visible.where( :name => name + " Karton" ).first
      carton_item = @vendor.items.visible.where( :sku => sku_carton ).first if carton_item.blank? and not sku_carton.blank? and not sku_carton.to_i.zero? # second chance to find something in case name has changed
      if carton_item
        attributes.merge! :sku => sku_carton unless sku_carton.blank? || sku_carton.to_i.zero? # protect against bad overwrites
        carton_item.attributes = attributes
        result = carton_item.save
        if result == false
          msg = "carton_item #{ carton_item.sku } #{ carton_item.name } could not be saved because #{ carton_item.errors.messages}"
          @messages << msg
          log_action msg, :light_red
        else
          Action.run(@vendor,carton_item,:on_import)
          log_action "[WHOLESALER IMPORT TYPE 2] Updating carton item #{carton_item.name} #{carton_item.sku}"
          @updated_items += 1
          @updated_item_ids << carton_item.id
        end
      else
        sku_carton = 'C' + (1000000000 + rand(9999999999)).to_s[0..12] if sku_carton.blank?  or sku_carton.to_i.zero?
        attributes.merge! :sku => sku_carton
        attributes.merge! :packaging_unit => packaging_unit_carton # only for create
        carton_item = Item.new; carton_item.vendor = @vendor; carton_item.attributes = attributes
        result = carton_item.save
        if result == false
          msg = "carton_item #{ carton_item.sku } #{ carton_item.name } could not be saved because #{ carton_item.errors.messages}"
          @messages << msg
          log_action msg, :light_red
        else
          Action.run(@vendor,carton_item,:on_import)
          log_action "[WHOLESALER IMPORT TYPE 2] Creating carton item #{carton_item.name} #{carton_item.sku}", :light_green
          @created_items += 1
          @created_item_ids << carton_item.id
        end
      end

      # pack
      attributes = {
        :shipper_sku => shipper_sku,
        :name => name + " Packung",
        :longname => longname + " Packung",
        :shortname => name + " Packung",
        :base_price => base_price_pack,
        :purchase_price => purchase_price_pack,
        :tax_profile_id => tax_profile_id,
        :category_id => category_id,
        :shipper_id => @shipper.id,
        :vendor_id => @vendor.id,
        :company_id => @company.id,
        :item_type_id => @item_type.id,
        :currency => @vendor.currency,
        :created_by => -102
      }
      sku_pack = columns[9].strip.gsub(/[^0-9a-zA-Z]/,'') # EAN_PA
      pack_item = @vendor.items.visible.where( :name => name + " Packung" ).first
      pack_item = @vendor.items.visible.where( :sku => sku_pack ).first if pack_item.blank? and not sku_pack.blank? and not sku_pack.to_i.zero? # second chance to find something in case name has changed
      if pack_item
        attributes.merge! :sku => sku_pack unless sku_pack.blank? || sku_pack.to_i.zero? # protect against bad overwrites
        pack_item.attributes = attributes
        result = pack_item.save
        if result == false
          msg = "pack_item #{ pack_item.sku } #{ pack_item.name } could not be saved because #{ pack_item.errors.messages}"
          @messages << msg
          log_action msg, :light_red
        else
          Action.run(@vendor,pack_item,:on_import)
          log_action "[WHOLESALER IMPORT TYPE 2] Updating pack item #{pack_item.name} #{pack_item.sku}"
          @updated_items += 1
          @updated_item_ids << pack_item.id
        end
      else
        sku_pack = 'C' + (1000000000 + rand(9999999999)).to_s[0..12] if sku_pack.blank? or sku_pack.to_i.zero?
        attributes.merge! :sku => sku_pack
        attributes.merge! :packaging_unit => packaging_unit_pack # only for create
        pack_item = Item.new; pack_item.vendor = @vendor; pack_item.attributes = attributes
        result = pack_item.save
        if result == false
          msg = "pack_item #{ pack_item.sku } #{ pack_item.name } could not be saved because #{ pack_item.errors.messages}"
          @messages << msg
          log_action msg, :light_red
        else
          Action.run(@vendor,pack_item,:on_import)
          log_action "[WHOLESALER IMPORT TYPE 2] Creating pack item #{pack_item.name} #{pack_item.sku}", :light_green
          @created_items += 1
          @created_item_ids << pack_item.id
        end
      end

      #debugger if name.include?("1 Diamond Crown No.3")
      #pack_item.parent = nil
      carton_item.child = pack_item
      result = carton_item.save
      #log_action "XXXX result #{ result } #{ carton_item.child.id }", :blue
      #carton_item.reload
      #debugger if carton_item.child.nil?
      if result == false
        msg = "carton_item #{ carton_item.sku } #{ carton_item.name } could not be assigned the child #{ pack_item.sku } because #{ carton_item.errors.messages }"
        @messages << msg
        log_action msg, :light_red
      end
      
      # piece
      attributes = {
        :shipper_sku => shipper_sku,
        :name => name + " Stk.",
        :longname => longname + " Stk.",
        :shortname => name + " Stk.",
        :base_price => base_price_piece,
        :purchase_price => purchase_price_piece,
        :tax_profile_id => tax_profile_id,
        :category_id => category_id,
        :shipper_id => @shipper.id,
        :vendor_id => @vendor.id,
        :company_id => @company.id,
        :item_type_id => @item_type.id,
        :currency => @vendor.currency,
        :created_by => -102
      }
      sku_piece = columns[19].strip.gsub(/[^0-9a-zA-Z]/,'') if columns[19] # EAN_STK
      piece_item = @vendor.items.visible.where( :name => name + " Stk." ).first
      piece_item = @vendor.items.visible.where( :sku => sku_piece ).first if piece_item.blank? and not sku_piece.blank? and not sku_piece.to_i.zero? # second chance to find something in case name has changed
      if piece_item
        attributes.merge! :sku => sku_piece unless sku_piece.blank? || sku_piece.to_i.zero? # protect against bad overwrites
        piece_item.attributes = attributes
        result = piece_item.save
        if result == false
          msg = "piece_item #{ piece_item.sku } #{ piece_item.name } could not be saved because #{ piece_item.errors.messages}"
          @messages << msg
          log_action msg, :light_red
        else
          Action.run(@vendor,piece_item,:on_import)
          log_action "[WHOLESALER IMPORT TYPE 2] Updating piece item #{piece_item.name} #{piece_item.sku}"
          @updated_items += 1
          @updated_item_ids << piece_item.id
        end
      else
        sku_piece = 'C' + (1000000000 + rand(9999999999)).to_s[0..12] if sku_piece.blank?  or sku_piece.to_i.zero?
        attributes.merge! :sku => sku_piece
        attributes.merge! :packaging_unit => 1 # only for create
        piece_item = Item.new; piece_item.vendor = @vendor; piece_item.attributes = attributes
        result = piece_item.save
        if result == false
          msg = "piece_item #{ piece_item.sku } #{ piece_item.name } could not be saved because #{ piece_item.errors.messages}"
          @messages << msg
          log_action msg, :light_red
        else
          Action.run(@vendor,piece_item,:on_import)
          log_action "[WHOLESALER IMPORT TYPE 2] Creating piece item #{piece_item.name} #{piece_item.sku}", :light_green
          @created_items += 1
          @created_item_ids << piece_item.id
        end
      end
      
      #piece_item.parent = nil
      pack_item.child = piece_item
      result = pack_item.save
      log_action "XXXX result #{ result } #{ pack_item.child.id }", :blue
      if result == false
        msg = "pack_item #{ pack_item.sku } #{ pack_item.name } could not be assigned the child #{ piece_item.sku } because #{ pack_item.errors.messages }"
        log_action msg, :light_red
      end
      
    end
  end

  def type3

    @lines.each do |row|
      @i += 1
      columns = row.chomp.split('","')

      match = /([a-zA-Z\s\W]*)(\d*)(\w*)/.match columns[1].strip
      name = match[1]
      weight = match[2]
      weight_metric = case match[3].upcase
        when 'G' then 'GR'
        when 'GR' then 'GR'
        when 'KG' then 'KG'
        when 'LITER' then 'LT'
        when 'LT' then 'LT'
	      when 'L' then 'LT'
        when 'ML' then 'ML'
      end
      sales_metric = 'STK'

      match = /([a-zA-Z\s\W]*)(\d*)(\w*)/.match columns[10].strip
      name = name + ' ' + match[1]
      weight = match[2] if weight.nil? or weight.blank?
      weight_metric ||= case match[3].upcase
        when 'G' then 'GR'
        when 'GR' then 'GR'
        when 'KG' then 'KG'
        when 'LITER' then 'LT'
        when 'LT' then 'LT'
        when 'L' then 'LT'
        when 'ML' then 'ML'
        else 'STK'
      end
      sales_metric = 'STK'

      tax = SalorBase.string_to_float(columns[4])
      tax_profile = @vendor.tax_profiles.visible.find_by_value tax
      tax_profile = TaxProfile.create(:name => "#{tax} %", :value => tax) unless tax_profile
      tax_profile_id = tax_profile.id

      base_price = SalorBase.string_to_float(columns[3])
      purchase_price = SalorBase.string_to_float(columns[13])
      
      sku = columns[0].gsub '"',''
      attributes = { :sku => sku, :name => name, :base_price => base_price, :purchase_price => purchase_price, :tax_profile_id => tax_profile_id, :sales_metric => sales_metric, :weight_metric => weight_metric, :weight => weight  }
      item = Item.find_by_sku(sku)
      if item
        item.update_attributes attributes
        Action.run(@vendor,item,:on_import)
        item.save
        @updated_items += 1
      else
        item = Item.new; carton_item.vendor = @vendor; carton_item.attributes = attributes
        Action.run(@vendor,item,:on_import)
        item.save
        @created_items += 1
      end

    end
  end

  def type4
    @lines.each do |row|
      columns = row.chomp.split('","')
      @i += 1
      sku = columns[0].gsub '"',''
      card = LoyaltyCard.find_by_sku(sku)
      if card
        card.customer.update_attributes :first_name => columns[2].gsub('"',''), :last_name => columns[1]
        updated_items += 1
      else
        customer = Customer.new :first_name => columns[2].gsub('"',''), :last_name => columns[1]
        customer.save
        card = LoyaltyCard.create :sku => sku, :customer_id => customer.id
        created_items += 1
      end
    end
  end
  
  # TODO: This needs to be made fit for SAAS: Scoping by Vendor and Company, for querying and creating new records
  def salor(trusted=true)
    csv = Kcsv.new(@lines, {:header => true,:separator => "\t"})
    csv.to_a.each do |rec|
      
      kls = Kernel.const_get(rec[:class])
      rec.delete(:class)
      
      if kls == Item then
        tp = @vendor.tax_profiles.visible.find_by_value(rec[:tax_profile_amount])
        if tp.nil?
          # Managing TaxProfiles is the user's responsibility alone. The software won't create that automatically.
          @messages << "No TaxProfile with #{ rec[:tax_profile_amount] }% found. You have to create it manually."
          next
        end
        
        cat = @vendor.categories.visible.find_by_name(rec[:category_name])
        rec.delete(:category_name)
        if rec[:location_name] then
          loc = Location.find_or_create_by_name(rec[:location_name]) if trusted
          if not loc.save then
            loc.errors.full_messages.each do |m|
#                 puts "Errors #{m}"
            end
          end
        end
        rec.delete(:location_name)
        item = @vendor.items.find_or_create_by_sku(rec[:sku])
        item.tax_profile = tp
        item.category = cat
        item.location = loc

        item.attributes = rec
        item.base_price = rec[:price]
#           puts "\n\nITEM IS: #{item.inspect}"
        @created_items += 1 if item.new_record?
        @updated_items += 1 if not item.new_record?
        
      elsif kls == Button then
        item = @vendore.buttons.find_or_create_by_sku(rec)
        item.attributes = rec
      elsif kls == Category then
        item = @vendor.categories.visible.find_or_create_by_sku(rec[:sku])
        item.attributes = rec
        @created_categories += 1 if item.new_record?
      elsif kls == LoyaltyCard and trusted then
        item = @vendor.loyalty_cards.find_or_create_by_sku(rec[:sku])
        item.attributes = rec
      elsif kls == Customer and trusted then
        if rec[:id] and Customer.exists?(rec[:id]) then
          item = @company.customers.find(rec[:id])
        else
          item = @company.customers.create
        end
        rec.delete(:id)
        item.attributes = rec
      elsif kls == Discount and trusted then
        item = @vendor.discounts.find_or_create_by_sku(rec[:sku])
        item.attributes = rec
      end
#         puts "Saving Item #{item.inspect}"
      if not item.save then
        SalorBase.log_action "DistUpload","failed to save #{item.attributes.inspect}"
        item.errors.full_messages.each do |msg|
          SalorBase.log_action "DistUpload","#{msg}"
#             puts "UnSaved #{item.sku} #{item.base_price} #{msg}"
        end 
      else
#           puts "Saved #{item.sku} #{item.base_price}"
      end
    end # end csv.to_a.each
  end # def dist(file)
  # {END}
end
