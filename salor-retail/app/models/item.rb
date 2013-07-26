# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

# TODO:
# * validate that gift card items always have a tax class of 0%. this is needed so that the taxes are correct when using gift cards. also, it would not make order total 0 in those cases where gift_card_amount is greater than order total.

class Item < ActiveRecord::Base

  include SalorScope
  include SalorBase

  belongs_to :category
  belongs_to :vendor
  belongs_to :company
  belongs_to :location
  belongs_to :tax_profile
  belongs_to :item_type
  belongs_to :item
  belongs_to :shipper
  has_many :order_items
  has_many :item_shippers
  has_many :item_stocks
  has_many :actions, :as => :model, :order => "weight asc"
  has_many :parts, :class_name => 'Item', :foreign_key => :part_id
  has_one :parent, :class_name => 'Item', :foreign_key => :child_id
  belongs_to :child, :class_name => 'Item'

  monetize :price_cents, :allow_nil => true
  monetize :gift_card_amount_cents, :allow_nil => true
  monetize :purchase_price_cents, :allow_nil => true
  monetize :buy_price_cents, :allow_nil => true
  monetize :manufacturer_price_cents, :allow_nil => true

  
  accepts_nested_attributes_for :item_shippers, :reject_if => lambda {|a| a[:shipper_sku].blank? }, :allow_destroy => true
  
  accepts_nested_attributes_for :item_stocks #, :reject_if => lambda {|a| (a[:stock_location_quantity].to_f +  a[:location_quantity].to_f == 0.00) }, :allow_destroy => true

  validates_presence_of :sku, :item_type, :vendor_id, :company_id
  #validates_uniqueness_of :sku, :scope => :vendor_id
  validate :sku_unique_in_visible

  before_save :run_actions
  before_save :cache_behavior
  
  COUPON_TYPES = [
      {:text => I18n.t('views.forms.percent_off'), :value => 1},
      {:text => I18n.t('views.forms.fixed_amount_off'), :value => 2},
      {:text => I18n.t('views.forms.buy_one_get_one'), :value => 3}
  ]
  
  SHIPPER_EXPORT_FORMATS = ['default_export','tobacco_land']
  
  SHIPPER_IMPORT_FORMATS = ['type1', 'type2', 'salor', 'optimalsoft']
  
  def sku_unique_in_visible
    if self.new_record?
      number = 0
    else
      number = 1
    end
    if self.vendor.items.visible.where(:sku => self.sku).count > number
      errors.add(:sku, I18n.t('activerecord.errors.messages.taken'))
      return
    end
  end
  
  
  #README
  # 1. The rails way would lead to many duplications
  # 2. The rails way would require us to reorganize all the translation files
  # 3. The rails way in this case is admittedly limited, by their own docs, and they suggest you implement your own
  # 4. Therefore, don't remove this code.
  def self.human_attribute_name(attrib, options={})
    begin
      trans = I18n.t("activerecord.attributes.#{attrib.downcase}", :raise => true) 
      return trans
    rescue
      SalorBase.log_action self.class, "trans error raised for activerecord.attributes.#{attrib} with locale: #{I18n.locale}"
      return super
    end
  end
  
  # ----- old name aliases getters
  
  def buyback_price
    return self.buy_price
  end
  
  def base_price
    return self.price
  end
  
  def amount_remaining
    return self.gift_card_amount
  end
  # ------ end old name aliases getters
  
  
  # ----- old name aliases setters
  def buyback_price=(p)
    self.buy_price_cents = self.string_to_float(p) * 100.0
  end
  
  def base_price=(p)
    p = self.string_to_float(p) * 100.0
    self.price_cents = p
  end
  
  def amount_remaining=(p)
    p = self.string_to_float(p) * 100.0
    self.gift_card_amount_cents = p
  end
  # ------ end old name aliases setters
  
  
  
  
  



  # ----- convenience methods for CSV
  def tax_profile_amount
    return self.tax_profile.value
  end
  
  def category_name
    return self.category.name if self.category
  end
  
  def location_name
    return self.location.name if self.location
  end
  
  def location_name=(n)
    self.location = self.vendor.locations.visible.find_by_name(n)
  end
  
  def tax_profile_name
    return self.tax_profile.name if self.tax_profile
  end
  
  def tax_profile_name=(n)
    self.tax_profile = self.vendor.tax_profiles.visible.find_by_name(n)
  end
  # ----- convenience methods for CSV
  
  
  # ----- CSV methods
  def to_csv(headers=nil)
    headers = Item.csv_headers if headers.nil?
    values = []
    headers.each do |h|
      values << '"' + self.send(h).to_s + '"'
    end
    return values.join("\t")
  end
  
    def self.csv_headers
    return [:class,:name,:sku,:price,:quantity,:quantity_sold,:tax_profile_name,:tax_profile_amount,:category_name,:location_name]
  end
  # ----- end CSV methods

  def gs1_regexp
    parts = self.gs1_format.split(",")
    return Regexp.new "(\\d{#{ parts[0] }})(\\d{#{ parts[1] }})"
  end

  def get_translated_name(locale=:en)
    locale = locale.to_s
    trans = read_attribute(:name_translations)
    val = ''
    if trans.nil? or trans.empty?
      val = read_attribute(:name)
    else
      hash = ActiveSupport::JSON.decode(trans)
      if hash[locale] then
        val = hash[locale]
      else
        val = read_attribute :name
      end
    end
    return val
  end
  
  def name_translations=(hash)
    write_attribute(:name_translations,hash.to_json)
  end
  
  def name_translations
    text = read_attribute(:name_translations)
    if text.nil? or text.empty? then
      return {}
    else
      return ActiveSupport::JSON.decode(text)
    end
  end

  def run_actions
    Action.run(self.vendor,self, :on_item_save)
  end
  
  def cache_behavior
    write_attribute :behavior, self.vendor.item_types.visible.find_by_id(self.item_type_id).behavior
  end
  
  def parent_sku
    if self.parent then
      return self.parent.sku
    else
      return nil
    end
  end
  
  def child_sku
    if self.child then
      return self.child.sku
    else
      return nil
    end
  end
  
  def child_sku=(string)
    if string.blank? then
      self.child = nil
      return
    end
    if self.sku == string then
      # this would create an infinite loop on self, we don't allow that
      self.child = nil
      return
    end
    child_item = self.vendor.items.visible.find_by_sku(string)
    if child_item then
      self.child_id = child_item.id
    end
  end
  
  def self.search(keywords)
    if keywords =~ /([\w]+) (\d{1,2}[\.\,]\d{1,2})/ then
      parts = keywords.match(/([\w]+) (\d{1,2}[\.\,]\d{1,2})/)
      price = SalorBase.string_to_float(parts[2]) * 100
      return Item.scopied.where("name LIKE '%#{parts[1]}%' and price_cents > #{(price - 500).to_i} and price_cents < #{(price + 500).to_i}")
    else
      return Item.scopied.where("name LIKE '%#{parts[1]}%'")
    end
  end
  
  def create_action
    action = Action.new
    action.vendor = self.vendor
    action.company = self.company
    action.model = self
    action.name = Time.now.strftime("%Y%m%d%H%M%S")
    result = action.save
    if result == false
      raise "Could not save Action because #{ action.errors.messages }"
    end
    return action
  end
  
  # ----- setters for advanced float parsing
  def purchase_price=(p)
    if p.class == String then
      p = self.string_to_float(p) * 100
      write_attribute(:purchase_price_cents,p)
      return
    end
    write_attribute(:purchase_price_cents,p)
  end

  def height=(p)
    p = self.string_to_float(p)
    write_attribute(:height,p)
  end
  
  def width=(p)
    p = self.string_to_float(p)
    write_attribute(:width,p)
  end
  
  def weight=(p)
    p = self.string_to_float(p)
    write_attribute(:weight,p)
  end
  
  def length=(p)
    p = self.string_to_float(p)
    write_attribute(:length,p)
  end
  
  def min_quantity=(p)
    p = self.string_to_float(p)
    write_attribute(:min_quantity,p)
  end
  
  def packaging_unit=(p)
    p = self.string_to_float(p)
    write_attribute(:packaging_unit,p)
  end
  
  def tax_profile_amount=(amnt)
    tp = self.vendor.tax_profiles.visible.find_by_value(SalorBase.to_float(amnt))
    if tp then
      self.tax_profile = tp
    end
  end
  # ----- end setters for advanced float parsing
  
  # ----- string setters for relations
  def category_name=(n)
    self.category = self.vendor.categories.visible.find_by_name(n)
  end
  # ----- end string setters for relations
  
  
  def assign_parts(hash={})
    self.parts = []
    hash ||= {}
    hash.each do |h|
      i = self.vendor.items.visible.find_by_sku(h[:sku])
      if i then
        i.is_part = true
        i.part_quantity = self.string_to_float(h[:part_quantity])
        result = i.save
        if result == false
          raise "Could not save Item because #{ i.errors.messages }"
        end
        self.parts << i
      end
    end
    result = self.save
    if result == false
      raise "Could not save Item because #{ i.errors.messages }"
    end
  end
  
  def from_shipment_item(si)
    i = Item.find_by_sku(si.sku)
    if i then
      if i.vendor == si.shipment.shipper then
        i.quantity -= si.quantity
      else
        i.quantity += si.quantity
        if si.stock_locations.any? then
          stock = i.item_stocks.find_by_stock_location_id(si.stock_locations.first.id)
          if stock then
            stock.update_attribute :stock_location_quantity, stock.stock_location_quantity + si.quantity
          end
        end
      end
      if si.purchase_price then
        i.purchase_price = si.purchase_price
      end
      return i
    else
      # puts "No item found..."
    end
    return nil
  end
  
  # includes quantity of all parents
  def quantity_with_recursion(depth=0)
    depth += 1
    raise "Item.quantity_with_recursion: Cap of 5 reached." if depth > 5
    if self.parent
      return self.quantity_with_stock + self.parent.packaging_unit * self.parent.quantity_with_recursion(depth)
    else
      return self.quantity_with_stock
    end
  end

  # if quantity reduced to smaller than zero, it 'takes' stock from parents. if quantity is positive or non-integer or there is no parent, it updates quantity directly. All quantity setters are "quantity_with_stock", meaning, if StockItems are defined for the Item, it will use those instead of the simple quantity field.
  def set_quantity_with_recursion(q, depth=0)
    log_action "[RECURSION] [#{ self.sku }] Called with q = #{ q.to_f }", :light_blue
    depth += 1
    raise "Item.set_quantity_recursively: Cap of 5 reached." if depth > 5
    
    q = 0 if q.blank?
    q = q.to_s.gsub(',','.')
    q = q.to_f.round(3)
    parent = self.parent
    
    if (q >= 0 or        # no recursion needed if zero or positive
        q != q.round or  # no recursion for non-integers
        self.quantity_with_stock != self.quantity_with_stock.round or # no recursion for non-integers
        (parent.nil? and q < 0) # no recursion if no parent
       )
      log_action "[RECURSION] [#{ self.sku }] Writing quantity #{ q.to_f } directly.", :light_blue
      self.quantity_with_stock = q
      result = self.save
      if result == false
        raise "[RECURSION] Could not save Item because #{ self.errors.messages }"
      end
      return
    end

    parent_units_needed = ( -q / parent.packaging_unit ).ceil
    log_action "[RECURSION] [#{ self.sku }] parent_units_needed #{ parent_units_needed }", :light_blue
    new_quantity_with_stock = parent_units_needed * parent.packaging_unit + q
    log_action "[RECURSION] [#{ self.sku }] setting quantity_with_stock to #{ new_quantity_with_stock }", :light_blue
    self.quantity_with_stock = new_quantity_with_stock
    result = self.save
    if result == false
      raise "[RECURSION] Could not save Item because #{ self.errors.messages }"
    end
    
    # now we need to reduce the quantity of the parent. this starts the recursion
    new_parent_quantity = parent.quantity_with_stock - parent_units_needed
    log_action "[RECURSION] [#{ self.sku }] parent.quantity_with_stock = #{ parent.quantity_with_stock }", :light_blue
    log_action "[RECURSION] [#{ self.sku }] parent_units_needed = #{ parent_units_needed }", :light_blue
    log_action "[RECURSION] [#{ self.sku }] Starting recursion with new_parent_quantity #{ new_parent_quantity }", :light_blue
    parent.set_quantity_with_recursion(new_parent_quantity, depth)
  end
  
  # returns the quantity of all ItemStocks, or if that feature is not used, only the Item quantity
  def quantity_with_stock
    item_stocks = self.item_stocks.visible
    if item_stocks.any?
      return item_stocks.sum(:location_quantity) + item_stocks.sum(:stock_location_quantity)
    else
      return read_attribute :quantity
    end
  end
  
  # sets the quantity of the item if no item_stocks defined, otherwise updates quantity of item_stocks of location as passed into this method. If no location is specified, it updates the first location.
  def quantity_with_stock=(q, location=nil)
    item_stocks = self.item_stocks.visible
    if item_stocks.any?
      if location
        log_action "Item.quantity=(): the user has specified which location to update. The user is responsible that there is an ItemStock for this Location. and that there is enough in Stock when the quantity is reduced."
        if location.class == Location
          item_stock = item_stocks.where('location_id IS NOT NULL').first
          item_stock.quantity = q
          item_stock.save
        elsif location.class == StockLocation
          item_stock = item_stocks.where('stock_location_id IS NOT NULL').first
          item_stock.quantity = q
          item_stock.save
        end
        
        
      else
        log_action "quantity=(): A location has not been passed to this method. this happens for example from the POS screen."
        
        # For this to work, all quantities in all ItemStocks have to be considered. We need to know the current quantity total of all ItemStocks, then calculate the difference to get the value we have to add or subtract to one or several of the ItemStocks.
        
        # this method gets the quantity total of all ItemStocks
        quantity_total = self.quantity_with_stock
        log_action "quantity=(): quantity_total = #{ quantity_total }"
        
        # the difference is positive when q is larger than quantity_total
        difference = q - quantity_total
        log_action "quantity=(): difference = #{ difference }"
        
        if difference > 0
          # Adding the difference to the first ItemStock that belongs to a Location. This maps approximately to what would happen in a store.
          item_stock = item_stocks.where('location_id IS NOT NULL').first
          item_stock.location_quantity += difference
          item_stock.save
          log_action "quantity=(): added #{ difference } to ItemStock #{ item_stock.id }"
          
        elsif difference < 0
          # First, we take from all ItemStocks which belong to a Location, as much as we can get (not reducing location_quantity below zero). If we still don't have enough, then we do the same for all ItemStocks which belong to a StockLocation. If we still don't have enough, we reduce the location_quantity of the first ItemStock which belongs to a Location to below zero. This maps approximately what happens in a store.
          
          amount_to_go = - difference
          log_action "quantity=(): subtraction: amount_to_go =  #{ amount_to_go }"
          
          item_stocks.where('location_id IS NOT NULL').each do |is|
            # we break this loop when we got enough
            break if amount_to_go == 0
            
            if (amount_to_go < 0)
              # just a security measure.
              raise "This method has taken more than it should have. Rounding errors?"
            end
            
            available_quantity = is.location_quantity
            if available_quantity - amount_to_go > 0
              log_action "quantity=(): this location ItemStock #{ is.id } has enough quantity to cover our demand"
              is.location_quantity -= amount_to_go
              is.save
              amount_to_go = 0
            else
              log_action "quantity=(): this location ItemStock #{ is.id } does not have enough quantity to cover our demand. subtracting everything (#{ is.location_quantity })."
              # this ItemStock does not have enough quantity to cover our demand. We still take what we can get, don't take more than available, and rememeber how much we have taken.
              amount_to_go -= is.location_quantity
              is.location_quantity = 0
              is.save
            end
          end
          
          item_stocks.where('stock_location_id IS NOT NULL').each do |is|
            # we break this loop when we got enough
            break if amount_to_go == 0
            
            if (amount_to_go < 0)
              # just a security measure.
              raise "This method has taken more than it should have. Rounding errors?"
            end
            
            available_quantity = is.stock_location_quantity
            if available_quantity - amount_to_go > 0
              log_action "quantity=(): this stock_location ItemStock #{ is.id } has enough quantity to cover our demand"
              is.stock_location_quantity -= amount_to_go
              is.save
              amount_to_go = 0
            else
              log_action "quantity=(): this stock_location ItemStock #{ is.id } does not have enough quantity to cover our demand. subtracting everything (#{ is.stock_location_quantity })."
              # this ItemStock does not have enough quantity to cover our demand. We still take what we can get, don't take more than available, and rememeber how much we have taken.
              amount_to_go -= is.location_quantity
              is.stock_location_quantity = 0
              is.save
            end
          end
          
          if amount_to_go > 0
            # looping through all ItemStocks hasn't satisfied our demand, so we have to force one of the ItemStocks into negative quantity
            item_stock = self.item_stocks.visible.first
            item_stock.location_quantity = - amount_to_go
            item_stock.save
            log_action "looping through all ItemStocks hasn't satisfied our demand, so we have to force one of the ItemStocks into negative quantity. setting ItemStock #{ item_stock.id } to #{ -amount_to_go }."
          end

        else
          log_action "quantity=(): difference is zero, nothing to do"
        end
      
      end # end user not specified a location
            
    else
      log_action "quantity=(): this Item does not have any stock_locations defined. in this case, we do not use this feature and simply set the quantity of the Item to #{ q }"
      self.quantity = q
    end
    
  end
  
  def hide(by)
    self.parent = nil
    self.child = nil
    self.hidden = true
    self.hidden_by = by
    self.hidden_at = Time.now
    result = self.save
    if result == false
      raise "Could not hide Item #{ self.id } because #{ self.errors.messages }"
    end
    
    b = self.vendor.buttons.visible.where(:sku => self.sku)
    b.update_all :hidden => true, :hidden_by => by, :hidden_at => Time.now
    
    is = self.item_stocks.visible
    is.update_all :hidden => true, :hidden_by => by, :hidden_at => Time.now
    
    #TODO: if part is deleted, remove from part container
    
  end
  
  def to_record
    attrs = self.attributes.clone
    attrs[:category] = self.category.name if self.category
    attrs[:location] = self.location.name if self.location
    attrs[:tax_profile] = self.tax_profile.name if self.tax_profile
    attrs[:parent_sku] = self.parent_sku if self.parent
    attrs[:child_sku] = self.child_sku if self.child
    attrs[:class] = self.class.to_s
    [ 
      :quantity, :quantity_sold,:created_at,
      :updated_at, :real_quantity,:quantity_buyback 
    ].each do |k|
      attrs.delete k
    end
    attrs
  end
  
  # Useful debug methods
  
  def recursive_parent_count(depth=0)
    return depth if depth > 5
    if self.parent
      return self.parent.recursive_parent_count(depth + 1)
    else
      return depth
    end
  end
  
  def recursive_sku_chain(depth=0, chain=[])
    depth += 1
    return chain << "and ongoing... " if depth > 5
    if self.parent
      chain << self.sku
      self.parent.recursive_sku_chain(depth, chain)
    else
      chain << self.sku
    end
  end
  
  def self.get_too_long_recursion_items
    too_long_item_ids = []
    Item.visible.where('child_id IS NULL OR child_id = 0').each do |i|
      too_long_item_ids << i.id if i.recursive_parent_count > 4
    end
    return too_long_item_ids
  end
  
  def self.find_self_loop_items
    Item.visible.where("id = child_id")
  end
  
  def self.clean_self_loop_items
    self_loop_items = self.find_infinite_loop_items
    self_loop_items.update_all :hidden => true, :hidden_by => -20, :hidden_at => Time.now
    self_loop_item_ids = self_loop_items.collect{ |i| i.id }
    return self_loop_item_ids
  end
  
  def self.find_duplicates
    Vendor.connection.execute("SELECT sku, count(*) FROM items WHERE hidden IS NULL OR hidden IS FALSE GROUP BY sku HAVING count(*) > 1").to_a
  end
  
  def self.clean_duplicates
    duplicates = find_duplicates
    deleted_item_ids = []
    duplicates.each do |d|
      duplicate_items = Item.visible.where(:sku => d[0])
      duplicate_items.update_all :hidden => true, :hidden_by => -21, :hidden_at => Time.now
      deleted_item_ids << duplicate_items.collect{ |i| i.id }
    end
    return deleted_item_ids
  end
  
  def self.find_nonhidden_items_with_hidden_child
    ids = []
    Item.visible.where("child_id IS NOT NULL OR child_id != 0").each do |i|
      ids << i.id if i.child and i.child.hidden == true
    end
    return ids
  end
  
  def self.clean_nonhidden_items_with_hidden_child
    ids = self.find_nonhidden_items_with_hidden_child
    Item.where(:id => ids).update_all :hidden => true, :hidden_by => -22, :hidden_at => Time.now
    return ids
  end
  
  def self.find_nonhidden_items_with_hidden_parent
    ids = []
    Item.visible.each do |i|
      ids << i.id if i.parent and i.parent.hidden == true
    end
    return ids
  end
  
  def self.clean_nonhidden_items_with_hidden_parent
    ids = self.find_nonhidden_items_with_hidden_parent
    Item.where(:id => ids).update_all :hidden => true, :hidden_by => -23, :hidden_at => Time.now
    return ids
  end
  
  def self.cleanup
    cleaned_up_ids = []
    cleaned_up_ids << self.clean_duplicates
    cleaned_up_ids << self.clean_infinite_loop_items
    cleaned_up_ids << self.clean_nonhidden_items_with_hidden_child
    cleaned_up_ids << self.clean_nonhidden_items_with_hidden_parent
    return cleaned_up_ids.flatten
  end


end
