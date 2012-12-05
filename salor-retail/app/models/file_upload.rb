# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.


class FileUpload
  # {START}
  def type1(shipper_name, file_lines) #danczek_tobaccoland_plattner_moosmayr
#     return { :updated_items => 1, :created_items => 1, :created_categories => 1, :created_tax_profiles => 1 }
    shipper = Shipper.scopied.visible.find_by_name(shipper_name)
    if shipper.nil?
      shipper = Shipper.create(:name => shipper_name, :vendor_id => $Vendor.id)
    end
    shipper_id = shipper ? shipper.id : nil
    i, updated_items, created_items, created_categories, created_tax_profiles,messages = [0,0,0,0,0,[]]
    if file_lines.first.include? '#' then
     delim = '#'
    elsif file_lines.first.include? ';'
     delim = ';'
    else
     raise "Could not detect delimiter in type 1 file: " + file_lines.first
    end
    file_lines.each do |row|
      i += 1
      next if i == 1 # skip headers
      columns = row.split(delim)

      shipper_sku = columns[0].strip

      name = columns[1].strip
      name.encode('UTF-8', :invalid => :replace, :undef => :replace)

      packaging_unit_pack = columns[12].gsub(',','.').to_f
      packaging_unit_carton = columns[11].gsub(',','.').to_f
      packaging_unit_container = columns[13].gsub(',','.').to_f

      base_price = columns[14].gsub(',','.').to_f / 100
      purchase_price = columns[15].gsub(',','.').to_f / 100

      #piece price calculation
      base_price_piece = base_price / packaging_unit_container
      purchase_price_piece = purchase_price / packaging_unit_container

      #pack price calculation
      base_price_pack = base_price_piece * packaging_unit_pack
      purchase_price_pack = purchase_price_piece * packaging_unit_pack

      #carton price calculation
      base_price_carton = base_price_piece * packaging_unit_carton
      purchase_price_carton = purchase_price_piece * packaging_unit_carton

      # packaging_unit_modification
      packaging_unit_carton = packaging_unit_carton / packaging_unit_pack

      if columns[36]
        tax_profile = TaxProfile.scopied.find_by_value(columns[36].to_f / 100)
      elsif columns[15] == columns[16]
        # since some wholesalers don't offer the tax field, guess
        tax_profile = TaxProfile.scopied.find_by_value(0)
      else
        tax_profile = TaxProfile.scopied.find_by_value(20)
      end
      tax_profile_id = tax_profile.id

      category = Category.find_by_name(columns[6].strip)
      catname = columns[6].strip
      if category.nil?
        category = Category.new :name => catname
        category.set_model_owner
        category.save
        created_categories += 1
      end
      category_id = category.id

      # carton
      attributes = { :shipper_sku => shipper_sku, :name => name + " Karton", :packaging_unit => packaging_unit_carton, :base_price => base_price_carton, :purchase_price => purchase_price_carton, :tax_profile_id => tax_profile_id, :category_id => category_id, :shipper_id => shipper_id }
      sku_carton = columns[8].strip
      carton_item = Item.where( :name => name + " Karton", :hidden => false ).first
      carton_item = Item.where( :sku => sku_carton, :hidden => false ).first if not carton_item and not sku_carton.empty? # second chance to find something in case name has changed
      if carton_item
        ActiveRecord::Base.logger.info "[WHOLESALER IMPORT TYPE 1] Updating carton item #{carton_item.name} #{carton_item.sku}"
        attributes.merge! :sku => sku_carton unless sku_carton.empty?
        carton_item.update_attributes attributes
        Action.run(carton_item,:on_import)
        carton_item.save
        updated_items += 1
      else
        sku_carton = 'C' + (1000000000 + rand(9999999999)).to_s[0..12] if sku_carton.empty?
        attributes.merge! :sku => sku_carton
        carton_item = Item.new attributes
        carton_item.set_model_owner
        Action.run(carton_item,:on_import)
        carton_item.save
        ActiveRecord::Base.logger.info "[WHOLESALER IMPORT TYPE 1] Creating carton item #{carton_item.name} #{carton_item.sku}"
        created_items += 1
      end
      
      # pack
      attributes = { :shipper_sku => shipper_sku, :name => name + " Packung", :packaging_unit => packaging_unit_pack, :base_price => base_price_pack, :purchase_price => purchase_price_pack, :tax_profile_id => tax_profile_id, :category_id => category_id, :shipper_id => shipper_id }
      sku_pack = columns[9].strip
      pack_item = Item.where( :name => name + " Packung", :hidden => false).first
      pack_item = Item.where( :sku => sku_pack, :hidden => false ).first if not pack_item and not sku_pack.empty? # second chance to find something in case name has changed
      if pack_item
        ActiveRecord::Base.logger.info "[WHOLESALER IMPORT TYPE 1] Updating pack item #{pack_item.name} #{pack_item.sku}"
        attributes.merge! :sku => sku_pack unless sku_pack.empty?
        pack_item.attributes = attributes
        Action.run(pack_item,:on_import)
        carton_item.reload
        carton_item.update_attribute(:child_id, pack_item.id) unless pack_item.id == carton_item.child_id or pack_item.sku == carton_item.sku
        pack_item.save
        updated_items += 1
      else
        sku_pack = 'C' + (1000000000 + rand(9999999999)).to_s[0..12] if sku_pack.empty?
        attributes.merge! :sku => sku_pack
        pack_item = Item.new attributes
        pack_item.set_model_owner
        Action.run(pack_item,:on_import)
        pack_item.save
        carton_item.reload
        carton_item.update_attribute(:child_id, pack_item.id) unless pack_item.id == carton_item.child_id or pack_item.sku == carton_item.sku
        pack_item.save
        ActiveRecord::Base.logger.info "[WHOLESALER IMPORT TYPE 1] Creating pack item #{pack_item.name} #{pack_item.sku}"
        created_items += 1
      end
      
      # piece
      attributes = { :shipper_sku => shipper_sku, :name => name + " Stk.", :packaging_unit => 1, :base_price => base_price_piece, :purchase_price => purchase_price_piece, :tax_profile_id => tax_profile_id, :category_id => category_id, :shipper_id => shipper_id }
      sku_piece = columns[19].strip if columns[19]
      piece_item = Item.where( :name => name + " Stk.", :hidden => false).first
      piece_item = Item.where( :sku => sku_piece, :hidden => false ).first if not piece_item and not sku_piece.empty? # second chance to find something in case name has changed
      if piece_item
        ActiveRecord::Base.logger.info "[WHOLESALER IMPORT TYPE 1] Updating piece item #{piece_item.name} #{piece_item.sku}"
        attributes.merge! :sku => sku_piece unless sku_piece.empty?
        piece_item.attributes = attributes
        Action.run(piece_item,:on_import)
        pack_item.reload
        pack_item.update_attribute(:child_id, piece_item.id) unless piece_item.id == pack_item.child_id or piece_item.sku == pack_item.sku
        piece_item.save
        updated_items += 1
      else
        sku_piece = 'C' + (1000000000 + rand(9999999999)).to_s[0..12] if sku_piece.empty?
        attributes.merge! :sku => sku_piece
        piece_item = Item.new attributes
        piece_item.set_model_owner
        Action.run(piece_item,:on_import)
        piece_item.save
        pack_item.reload
        pack_item.update_attribute(:child_id, piece_item.id) unless piece_item.id == pack_item.child_id or piece_item.sku == pack_item.sku
        piece_item.save
        ActiveRecord::Base.logger.info "[WHOLESALER IMPORT TYPE 1] Creating piece item #{piece_item.name} #{piece_item.sku}"
        created_items += 1
      end
    end
    return { :updated_items => updated_items, :created_items => created_items, :created_categories => created_categories, :created_tax_profiles => created_tax_profiles }
  end

  #
  def type2(shipper_name, file_lines) #house of smoke, dios
    
    shipper = Shipper.find_by_name(shipper_name)
    if shipper.nil?
      shipper = Shipper.create(:name => shipper_name, :vendor_id => $Vendor.id)
    end
    shipper_id = shipper ? shipper.id : nil
    
    i, updated_items, created_items, created_categories, created_tax_profiles = [0,0,0,0,0]
    if file_lines[0].include?('#') or file_lines[1].include?('#') then
     delim = '#'
    elsif file_lines[0].include?(';') or file_lines[1].include?(';')
     delim = ';'
    else
      raise "Could not detect delimiter in House Of Smoke or Dios"
    end
    file_lines.each do |row|
      i += 1
      next if i == 1 # skip headers
      next if row.strip.empty? # dios has an empty first line
      columns = row.chomp.split(delim)

      shipper_sku = columns[0].strip

      name = columns[1].strip
      name.encode('UTF-8', :invalid => :replace, :undef => :replace)

      packaging_unit_pack = columns[12].gsub(',','.').to_f
      packaging_unit_pack = 1 if packaging_unit_pack.zero?
      packaging_unit_carton = columns[11].gsub(',','.').to_f
      packaging_unit_carton = 1 if packaging_unit_carton.zero?
      packaging_unit_container = columns[13].gsub(',','.').to_f
      packaging_unit_container = 1 if packaging_unit_container.zero?

      base_price = columns[14].gsub(',','.').to_f / 100
      purchase_price = columns[15].gsub(',','.').to_f / 100

      # piece price calculation
      base_price_piece = base_price / packaging_unit_container
      purchase_price_piece = purchase_price / packaging_unit_container

      # pack price calculation
      base_price_pack =  base_price_piece * packaging_unit_pack
      purchase_price_pack =  purchase_price_piece * packaging_unit_pack

      # carton price calculation
      base_price_carton = base_price_piece * packaging_unit_carton
      purchase_price_carton = purchase_price_piece * packaging_unit_carton

      # packaging_unit_modification
      packaging_unit_carton = packaging_unit_carton / packaging_unit_pack

      if columns[36]
        tax_profile = TaxProfile.scopied.find_by_value(columns[36].to_f / 100)
      elsif columns[15] == columns[16]
        # since some wholesalers don't offer the tax field, guess
        tax_profile = TaxProfile.scopied.find_by_value(0)
      else
        tax_profile = TaxProfile.scopied.find_by_value(20)
      end
      tax_profile_id = tax_profile.id

      category = Category.find_by_name(columns[6].strip)
      catname = columns[6].strip
      if category.nil?
        category = Category.new :name => catname
        category.set_model_owner
        category.save
        created_categories += 1
      end
      category_id = category.id

      # carton
      attributes = { :shipper_sku => shipper_sku, :name => name + " Karton", :packaging_unit => packaging_unit_carton, :base_price => base_price_carton, :purchase_price => purchase_price_carton, :tax_profile_id => tax_profile_id, :category_id => category_id, :shipper_id => shipper_id }
      sku_carton = columns[8].strip
      carton_item = Item.where( :name => name + " Karton", :hidden => false ).first
      carton_item = Item.where( :sku => sku_carton, :hidden => false ).first if not carton_item and not sku_carton.empty? # second chance to find something in case name has changed
      if carton_item
        ActiveRecord::Base.logger.info "[WHOLESALER IMPORT TYPE 2] Updating carton item #{carton_item.name} #{carton_item.sku}"
        attributes.merge! :sku => sku_carton unless sku_carton.empty?
        carton_item.update_attributes attributes
        Action.run(carton_item,:on_import)
        carton_item.save
        updated_items += 1
      else
        sku_carton = 'C' + (1000000000 + rand(9999999999)).to_s[0..12] if sku_carton.empty?
        attributes.merge! :sku => sku_carton
        carton_item = Item.new attributes
        carton_item.set_model_owner
        Action.run(carton_item,:on_import)
        carton_item.save
        ActiveRecord::Base.logger.info "[WHOLESALER IMPORT TYPE 2] Creating carton item #{carton_item.name} #{carton_item.sku}"
        created_items += 1
      end

      # pack
      attributes = { :shipper_sku => shipper_sku, :name => name + " Packung", :packaging_unit => packaging_unit_pack, :base_price => base_price_pack, :purchase_price => purchase_price_pack, :tax_profile_id => tax_profile_id, :category_id => category_id, :shipper_id => shipper_id }
      sku_pack = columns[9].strip
      pack_item = Item.where( :name => name + " Packung", :hidden => false ).first
      pack_item = Item.where( :sku => sku_pack, :hidden => false ).first if not pack_item and not sku_pack.empty? # second chance to find something in case name has changed
      if pack_item
        ActiveRecord::Base.logger.info "[WHOLESALER IMPORT TYPE 2] Updating pack item #{pack_item.name} #{pack_item.sku}"
        attributes.merge! :sku => sku_pack unless sku_pack.empty?
        pack_item.update_attributes attributes
        Action.run(pack_item,:on_import)
        carton_item.reload
        carton_item.update_attribute(:child_id, pack_item.id) unless pack_item.id == carton_item.child_id or pack_item.sku == carton_item.sku
        pack_item.save
        updated_items += 1
      else
        sku_pack = 'C' + (1000000000 + rand(9999999999)).to_s[0..12] if sku_pack.empty?
        attributes.merge! :sku => sku_pack
        pack_item = Item.new attributes
        pack_item.set_model_owner
        Action.run(pack_item,:on_import)
        pack_item.save
        carton_item.reload
        carton_item.update_attribute(:child_id, pack_item.id) unless pack_item.id == carton_item.child_id or pack_item.sku == carton_item.sku
        pack_item.save
        ActiveRecord::Base.logger.info "[WHOLESALER IMPORT TYPE 2] Creating pack item #{pack_item.name} #{pack_item.sku}"
        created_items += 1
      end

      # piece
      attributes = { :shipper_sku => shipper_sku, :name => name + " Stk.", :packaging_unit => 1, :base_price => base_price_piece, :purchase_price => purchase_price_piece, :tax_profile_id => tax_profile_id, :category_id => category_id, :shipper_id => shipper_id }
      sku_piece = columns[19].strip if columns[19]
      piece_item = Item.where( :name => name + " Stk.", :hidden => false ).first
      carton_item = Item.where( :sku => sku_piece, :hidden => false ).first if not piece_item and not sku_piece.empty? # second chance to find something in case name has changed
      if piece_item
        ActiveRecord::Base.logger.info "[WHOLESALER IMPORT TYPE 2] Updating piece item #{piece_item.name} #{piece_item.sku}"
        attributes.merge! :sku => sku_piece unless sku_piece.empty?
        piece_item.update_attributes attributes
        Action.run(piece_item,:on_import)
        pack_item.reload
        pack_item.update_attribute(:child_id, piece_item.id) unless piece_item.id == pack_item.child_id or piece_item.sku == pack_item.sku
        piece_item.save
        updated_items += 1
      else
        sku_piece = 'C' + (1000000000 + rand(9999999999)).to_s[0..12] if sku_piece.nil? or sku_piece.empty?
        attributes.merge! :sku => sku_piece
        piece_item = Item.new attributes
        piece_item.set_model_owner
        Action.run(piece_item,:on_import)
        piece_item.save
        pack_item.reload
        pack_item.update_attribute(:child_id, piece_item.id) unless piece_item.id == pack_item.child_id or piece_item.sku == pack_item.sku
        piece_item.save
        ActiveRecord::Base.logger.info "[WHOLESALER IMPORT TYPE 2] Creating piece item #{piece_item.name} #{piece_item.sku}"
        created_items += 1
      end
    end
    return { :updated_items => updated_items, :created_items => created_items, :created_categories => created_categories, :created_tax_profiles => created_tax_profiles }
  end

  #
  def type3(file_lines) #Optimalsoft Items
    i, updated_items, created_items, created_categories, created_tax_profiles = [0,0,0,0,0]
    file_lines.each do |row|
      i += 1
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
      # unless match[1].empty?
      #   description = name
      #   name = match[1]
      # end
      name = name + ' ' + match[1]
      weight = match[2] if weight.nil? or weight.empty?
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
      tax_profile = TaxProfile.scopied.find_by_value tax
      tax_profile = TaxProfile.create(:name => "#{tax} %", :value => tax) unless tax_profile
      tax_profile_id = tax_profile.id

      base_price = SalorBase.string_to_float(columns[3])
      purchase_price = SalorBase.string_to_float(columns[13])
      
      sku = columns[0].gsub '"',''
      attributes = { :sku => sku, :name => name, :base_price => base_price, :purchase_price => purchase_price, :tax_profile_id => tax_profile_id, :sales_metric => sales_metric, :weight_metric => weight_metric, :weight => weight  }
      item = Item.find_by_sku(sku)
      if item
        item.update_attributes attributes
        Action.run(item,:on_import)
        item.save
        updated_items += 1
      else
        item = Item.new attributes
        item.set_model_owner
        Action.run(item,:on_import)
        item.save
        created_items += 1
      end

    end
    GlobalErrors.append('views.notice.wholesaler_upload_report', nil, { :updated_items => updated_items, :created_items => created_items, :created_categories => created_categories, :created_tax_profiles => created_tax_profiles })
  end

  #
  def type4(file_lines) #Optimalsoft Customers
    i, updated_items, created_items, created_categories, created_tax_profiles = [0,0,0,0,0]
    file_lines.each do |row|
      columns = row.chomp.split('","')
      #next if columns[2].gsub('"','').empty? and columns[1].empty?
      i += 1
      sku = columns[0].gsub '"',''
      card = LoyaltyCard.find_by_sku(sku)
      if card
        card.customer.update_attributes :first_name => columns[2].gsub('"',''), :last_name => columns[1]
        updated_items += 1
      else
        customer = Customer.new :first_name => columns[2].gsub('"',''), :last_name => columns[1]
        customer.set_model_owner
        customer.save
        card = LoyaltyCard.create :sku => sku, :customer_id => customer.id
        created_items += 1
      end
    end
  end

  #
  def salor(file_lines)
    i, updated_items, created_items, created_categories, created_tax_profiles = [0,0,0,0,0]
    if file_lines.first.include? '#' then
     delim = '#'
    elsif file_lines.first.include? ';'
     delim = ';'
    else
      raise "Could not detect delimiter in salor"
    end
    file_lines.each do |row|
      i += 1
      next if i == 1 # skip headers
      columns = row.chomp.split(delim)

      tax_value = columns[3].gsub(',','.').to_f*100
      tax_profile = TaxProfile.find_by_value(tax_value)
      if tax_profile.nil?
        tax_profile = TaxProfile.create :name => tax_value, :value => tax_value
        created_tax_profiles += 1
      end
      tax_profile_id = tax_profile.id

      if columns[8]
        category = Category.find_by_name(columns[8].strip)
        catname = columns[8].strip
      else
        category = nil
        catname = '-'
      end
      if category.nil?
        category = Category.new :name => catname
        category.set_model_owner
        category.save
        created_categories += 1
      end
      category_id = category.id

      weight = columns[5].gsub(',','.').to_f if columns[5]

      attributes = { :sku => columns[0].strip, :name => columns[1].strip, :base_price => columns[2], :tax_profile_id => tax_profile_id, :sales_metric => columns[4], :weight => weight, :weight_metric => columns[6], :purchase_price => columns[7], :category_id => category_id }

      item = Item.find_by_sku(columns[0])
      if item
        item.update_attributes attributes
        updated_items += 1
      else
        item = Item.new attributes
        item.set_model_owner
        item.save
        created_items += 1
      end
    end
    GlobalErrors.append('views.notice.wholesaler_upload_report', nil, { :updated_items => updated_items, :created_items => created_items, :created_categories => created_categories, :created_tax_profiles => created_tax_profiles })
  end
  def dist(file,trusted)
    i, updated_items, created_items, created_categories, created_tax_profiles = [0,0,0,0,0]
    csv = Kcsv.new(file,{:header => true})
    csv.to_a.each do |rec|
      begin
        kls = Kernel.const_get(rec[:class])
        rec.delete(:class)
        if kls == Item then
          begin
          tp = TaxProfile.find_or_create_by_value(rec[:tax_profile_amount])
          created_tax_profiles += 1 if tp.new_record?
          cat = Category.find_by_name(rec[:category_name])
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
          item = Item.find_or_create_by_sku(rec[:sku])
          item.tax_profile = tp
          item.category = cat
          item.location = loc
          item.attributes = rec
          item.base_price = rec[:base_price]
#           puts "\n\nITEM IS: #{item.inspect}"
          created_items += 1 if item.new_record?
          updated_items += 1 if not item.new_record?
          rescue
#             puts "## ERROR #{$!.inspect}"
          end
        elsif kls == Button then
          item = Button.find_or_create_by_sku(rec)
          item.attributes = rec
        elsif kls == Category then
          item = Category.find_or_create_by_sku(rec[:sku])
          item.attributes = rec
          created_categories += 1 if item.new_record?
        elsif kls == LoyaltyCard and trusted then
          item = LoyaltyCard.find_or_create_by_sku(rec[:sku])
          item.attributes = rec
        elsif kls == Customer and trusted then
          item = Customer.find_or_create_by_sku(rec[:sku])
          item.attributes = rec
        elsif kls == Discount and trusted then
          item = Discount.find_or_create_by_sku(rec[:sku])
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
      rescue 
         GlobalErrors << ["Error"]
      end
      $Notice = I18n.t("wholesaler_upload_report",{ :updated_items => updated_items, :created_items => created_items, :created_categories => created_categories, :created_tax_profiles => created_tax_profiles })
    end # end csv.to_a.each
  end # def dist(file)
  # {END}
end
