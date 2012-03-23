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

#
class FileUpload
  def type1(file_lines) #danczek_tobaccoland_plattner
    i, updated_items, created_items, created_categories, created_tax_profiles = [0,0,0,0,0]
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

      name = Iconv.new('UTF-8//TRANSLIT', 'ISO-8859-15').iconv(columns[1].strip)

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
      attributes = { :shipper_sku => shipper_sku, :name => name + " Karton", :packaging_unit => packaging_unit_carton, :base_price => base_price_carton, :purchase_price => purchase_price_carton, :tax_profile_id => tax_profile_id, :category_id => category_id }
      sku_carton = columns[8].strip
      carton_item = Item.where( :name => name + " Karton", :hidden => false ).first
      carton_item = Item.where( :sku => sku_carton ).first if not carton_item and not sku_carton.empty? # second chance to find something in case name has changed
      if carton_item
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
        created_items += 1
      end

      # pack
      attributes = { :shipper_sku => shipper_sku, :name => name + " Packung", :packaging_unit => packaging_unit_pack, :base_price => base_price_pack, :purchase_price => purchase_price_pack, :tax_profile_id => tax_profile_id, :category_id => category_id }
      sku_pack = columns[9].strip
      pack_item = Item.where( :name => name + " Packung", :hidden => false).first
      pack_item = Item.where( :sku => sku_pack ).first if not pack_item and not sku_pack.empty? # second chance to find something in case name has changed
      if pack_item
        pack_item.attributes = attributes
        Action.run(pack_item,:on_import)
        pack_item.parent = carton_item if not pack_item.sku == carton_item.sku
        pack_item.save
        updated_items += 1
      else
        sku_pack = 'C' + (1000000000 + rand(9999999999)).to_s[0..12] if sku_pack.empty?
        attributes.merge! :sku => sku_pack
        pack_item = Item.new attributes
        pack_item.set_model_owner
        Action.run(pack_item,:on_import)
        pack_item.save
        pack_item.parent = carton_item if not pack_item.sku == carton_item.sku
        pack_item.save
        created_items += 1
      end

      # piece
      attributes = { :shipper_sku => shipper_sku, :name => name + " Stk.", :packaging_unit => 1, :base_price => base_price_piece, :purchase_price => purchase_price_piece, :tax_profile_id => tax_profile_id, :category_id => category_id }
      sku_piece = columns[19].strip if columns[19]
      piece_item = Item.where( :name => name + " Stk.", :hidden => false).first
      piece_item = Item.where( :sku => sku_piece ).first if not piece_item and not sku_piece.empty? # second chance to find something in case name has changed
      if piece_item
        piece_item.attributes = attributes
        Action.run(piece_item,:on_import)
        piece_item.parent = pack_item if not pack_item.sku == piece_item.sku
        piece_item.save
        updated_items += 1
      else
        sku_piece = 'C' + (1000000000 + rand(9999999999)).to_s[0..12] if sku_piece.empty?
        attributes.merge! :sku => sku_piece
        piece_item = Item.new attributes
        piece_item.set_model_owner
        Action.run(piece_item,:on_import)
        piece_item.save
        piece_item.parent = pack_item if not pack_item.sku == piece_item.sku
        piece_item.save
        created_items += 1
      end
    end
    GlobalErrors.append('views.notice.wholesaler_upload_report', nil, { :updated_items => updated_items, :created_items => created_items, :created_categories => created_categories, :created_tax_profiles => created_tax_profiles })
  end

  #
  def type2(file_lines) #house of smoke, dios
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

      name = Iconv.new('UTF-8//TRANSLIT', 'UTF-8').iconv(columns[1].strip)

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
      attributes = { :shipper_sku => shipper_sku, :name => name + " Karton", :packaging_unit => packaging_unit_carton, :base_price => base_price_carton, :purchase_price => purchase_price_carton, :tax_profile_id => tax_profile_id, :category_id => category_id }
      sku_carton = columns[8].strip
      carton_item = Item.where( :name => name + " Karton", :hidden => false ).first
      carton_item = Item.where( :sku => sku_carton ).first if not carton_item and not sku_carton.empty? # second chance to find something in case name has changed
      if carton_item
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
        created_items += 1
      end

      # pack
      attributes = { :shipper_sku => shipper_sku, :name => name + " Packung", :packaging_unit => packaging_unit_pack, :base_price => base_price_pack, :purchase_price => purchase_price_pack, :tax_profile_id => tax_profile_id, :category_id => category_id }
      sku_pack = columns[9].strip
      pack_item = Item.where( :name => name + " Packung", :hidden => false ).first
      pack_item = Item.where( :sku => sku_pack ).first if not pack_item and not sku_pack.empty? # second chance to find something in case name has changed
      if pack_item
        pack_item.update_attributes attributes
        Action.run(pack_item,:on_import)
        pack_item.parent = carton_item if not pack_item.sku == carton_item.sku
        pack_item.save
        updated_items += 1
      else
        sku_pack = 'C' + (1000000000 + rand(9999999999)).to_s[0..12] if sku_pack.empty?
        attributes.merge! :sku => sku_pack
        pack_item = Item.new attributes
        pack_item.set_model_owner
        Action.run(pack_item,:on_import)
        pack_item.save
        pack_item.parent = carton_item if not pack_item.sku == carton_item.sku
        pack_item.save
        created_items += 1
      end

      # piece
      attributes = { :shipper_sku => shipper_sku, :name => name + " Stk.", :packaging_unit => 1, :base_price => base_price_piece, :purchase_price => purchase_price_piece, :tax_profile_id => tax_profile_id, :category_id => category_id }
      sku_piece = columns[19].strip if columns[19]
      piece_item = Item.where( :name => name + " Stk.", :hidden => false ).first
      carton_item = Item.where( :sku => sku_piece ).first if not piece_item and not sku_piece.empty? # second chance to find something in case name has changed
      if piece_item
        piece_item.update_attributes attributes
        Action.run(piece_item,:on_import)
        piece_item.parent = pack_item if not pack_item.sku == piece_item.sku
        piece_item.save
        updated_items += 1
      else
        sku_piece = 'C' + (1000000000 + rand(9999999999)).to_s[0..12] if sku_piece.nil? or sku_piece.empty?
        attributes.merge! :sku => sku_piece
        piece_item = Item.new attributes
        piece_item.set_model_owner
        Action.run(piece_item,:on_import)
        piece_item.save
        piece_item.parent = pack_item if not pack_item.sku == piece_item.sku
        piece_item.save
        created_items += 1
      end
    end
    GlobalErrors.append('views.notice.wholesaler_upload_report', nil, { :updated_items => updated_items, :created_items => created_items, :created_categories => created_categories, :created_tax_profiles => created_tax_profiles })
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
end
