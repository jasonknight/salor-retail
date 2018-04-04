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
  has_many :histories, :as => :model
  has_many :order_items
  has_many :item_shippers
  has_many :item_stocks
  has_many :stock_transactions, :as => :to
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
  
  accepts_nested_attributes_for :item_stocks, :allow_destroy => true #, :reject_if => lambda {|a| (a[:stock_location_quantity].to_f +  a[:location_quantity].to_f == 0.00) }

  validates_presence_of :sku, :item_type, :vendor_id, :company_id, :tax_profile_id, :currency
  
  validate :sku_unique_in_visible, :if => :sku_is_not_weird
  validate :not_selfloop
  validate :not_too_long_child_chain
  validate :not_too_long_parent_chain
  validate :no_child_duplicate
  validate :not_negative
  
  before_save :run_onsave_actions
  before_save :cache_behavior
  
  COUPON_TYPES = [
      {:text => I18n.t('views.forms.percent_off'), :value => 1},
      {:text => I18n.t('views.forms.fixed_amount_off'), :value => 2},
      {:text => I18n.t('views.forms.buy_one_get_one'), :value => 3}
  ]
  
  SHIPPER_EXPORT_FORMATS = ['default_export','tobacco_land']
  
  SHIPPER_IMPORT_FORMATS = ['type1', 'type2', 'salor', 'optimalsoft']
  
  def not_negative
    if self.base_price.fractional < 0
      errors.add(:base_price, I18n.t('system.errors.dont_use_negative_prices'))
    end
    
    if self.buyback_price.fractional < 0
      errors.add(:buyback_price, I18n.t('system.errors.dont_use_negative_prices'))
    end
  end
  
  def sku_is_not_weird
    if not self.sku == self.sku.gsub(/[^-0-9a-zA-Z]/,'') then
      errors.add(:sku, I18n.t('system.errors.dont_use_weird_skus'))
      return false
    end
    return true
  end
  
  def sku_unique_in_visible
    if self.new_record?
      error = self.vendor.items.visible.where(:sku => self.sku).count > 0
    else
      error = self.vendor.items.visible.where("sku = '#{self.sku}' AND NOT id = #{ self.id }").count > 0
    end
    if error == true
      errors.add(:sku, I18n.t('activerecord.errors.messages.taken'))
      return
    end
  end
  
  def not_selfloop
    if self.sku == self.child_sku
      errors.add(:child_sku, "cannot have the same SKU as this item!")
      return
    end
  end
  
  def not_too_long_child_chain
    chain = self.recursive_child_sku_chain
    chain.shift
    if chain.include? self.sku
      errors.add(:child_sku, "would create a child-infinite loop!")
      return
    end
#     if self.recursive_child_count > 2
#       errors.add(:child_sku, "would create a too long child chain")
#       return
#     end
  end
  
  def not_too_long_parent_chain
    chain = self.recursive_parent_sku_chain
    chain.shift
    if chain.include? self.sku
      errors.add(:child_sku, "would create a parent-infinite loop!")
      return
    end
#     if self.recursive_parent_count > 2
#       errors.add(:child_sku, "would create a too long parent chain")
#       return
#     end
  end
  
  def no_child_duplicate
    child_item = self.vendor.items.visible.find_by_sku(self.child_sku)
    return if child_item.nil?
    
    c_id = child_item.id
    items_which_have_this_child = self.vendor.items.visible.where("sku != '#{ self.sku_was }'").where(:child_id => c_id)
    if items_which_have_this_child.any?
      info = items_which_have_this_child.collect {|i| [i.id, i.sku] }
      errors.add(:child_sku, "items #{ info.inspect } already have this child #{ self.child_sku }")
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
      #SalorBase.log_action self.class, "trans error raised for activerecord.attributes.#{attrib} with locale: #{I18n.locale}"
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
    self.buy_price_cents = (self.string_to_float(p, :locale => self.vendor.region) * 100).round
  end
  
  def base_price=(pricestring)
    price_float = self.string_to_float(pricestring, :locale => self.vendor.region)
    price_c = (price_float * 100).round
    self.price_cents = price_c
  end
  
  def amount_remaining=(p)
    p = (self.string_to_float(p, :locale => self.vendor.region) * 100).round
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
    return [
                :class, :name, :sku, :price, :quantity, :behavior, 
                :child_sku, :tax_profile_name, :tax_profile_amount, 
                :category_name, :location_name
    ]
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

  def run_onsave_actions
    # Action.run(self.vendor,self, :on_item_save) # MF: disabled this because it would run even when another Action would save an item, so we would have nested saves which are difficult to debug.
  end
  
  def cache_behavior
    write_attribute :behavior, self.vendor.item_types.visible.find_by_id(self.item_type_id).behavior
  end

  def behavior=(b)
    it = self.vendor.item_types.visible.find_by_behavior(b)
    if it then
      self.item_type = it
      write_attribute :behavior, it.behavior
    end
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
    action.whento = "on_import"
    action.behavior = "divide"
    action.name = self.name
    result = action.save
    if result == false
      raise "Could not save Action because #{ action.errors.messages }"
    end
    return action
  end
  
  # ----- setters for advanced float parsing
  def purchase_price=(p)
    p = (self.string_to_float(p, :locale => self.vendor.region) * 100).ceil
    write_attribute(:purchase_price_cents, p)
  end

  def height=(p)
    p = self.string_to_float(p, :locale => self.vendor.region)
    write_attribute(:height,p)
  end
  
  def width=(p)
    p = self.string_to_float(p, :locale => self.vendor.region)
    write_attribute(:width,p)
  end
  
  def weight=(p)
    p = self.string_to_float(p, :locale => self.vendor.region)
    write_attribute(:weight,p)
  end
  
  def length=(p)
    p = self.string_to_float(p, :locale => self.vendor.region)
    write_attribute(:length,p)
  end
  
  def min_quantity=(p)
    p = self.string_to_float(p, :locale => self.vendor.region)
    write_attribute(:min_quantity,p)
  end
  
  def packaging_unit=(p)
    p = self.string_to_float(p, :locale => self.vendor.region)
    write_attribute(:packaging_unit,p)
  end
  
  def tax_profile_amount=(amnt)
    tp = self.vendor.tax_profiles.visible.find_by_value(SalorBase.string_to_float(amnt))
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
    return if hash.nil? or hash == {}
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
      raise "Could not save Item because #{ self.errors.messages }"
    end
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

  
  
  # returns the quantity of all ItemStocks, or if that feature is not used, only the Item quantity
  def quantity_with_stock
    item_stocks = self.item_stocks.visible
    if item_stocks.any?
      return item_stocks.sum(:quantity)
    else
      return read_attribute :quantity
    end
  end
  
  def self.find_like_sku_in_hidden(sku)
    Item.hidden.where("sku LIKE %#{ sku }%")
  end
  
  def hide(by_id)
    self.parent = nil
    self.child = nil
    self.hidden = true
    self.sku = "OLD#{ Time.now.strftime("%Y%m%d%H%M%S") }#{ self.sku }"
    self.hidden_by = by_id
    self.hidden_at = Time.now
    self.save!
    
    b = self.vendor.buttons.visible.where(:sku => self.sku)
    b.update_all :hidden => true, :hidden_by => by_id, :hidden_at => Time.now
    
    is = self.item_stocks.visible
    is.update_all :hidden => true, :hidden_by => by_id, :hidden_at => Time.now
    
    #TODO: if part is deleted, remove from part container
    #TODO: remove actions
    
  end
  
  def shipper_name
    if self.shipper
      return self.shipper.name
    else
      return ""
    end
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
    return Float::INFINITY if depth > 5
    if self.parent
      return self.parent.recursive_parent_count(depth + 1)
    else
      return depth
    end
  end
  
  def recursive_child_count(depth=0)
    return Float::INFINITY if depth > 5
    if self.child
      return self.child.recursive_child_count(depth + 1)
    else
      return depth
    end
  end
  
  def recursive_parent_sku_chain(depth=0, chain=[])
    depth += 1
    return chain << "..." if depth > 5
    if self.parent
      chain << self.sku
      self.parent.recursive_parent_sku_chain(depth, chain)
    else
      chain << self.sku
    end
  end
  
  def unlink
    self.parent = nil
    self.child = nil
    self.save!
  end
  
  def recursive_child_sku_chain(depth=0, chain=[])
    depth += 1
    return chain << "..." if depth > 5
    if self.child
      chain << self.sku
      self.child.recursive_child_sku_chain(depth, chain)
    else
      chain << self.sku
    end
  end
  
  def self.get_zero_child_ids # Item.get_zero_child_ids
    Item.where(:child_id => 0).collect { |i| i.id }
  end
  
  def self.get_self_loop_ids # Item.get_self_loop_ids
    Item.visible.where("id = child_id").collect { |i| i.id }
  end
  
  def self.get_too_long_parent_recursion_ids # Item.get_too_long_parent_recursion_ids 
    too_long_item_ids = []
    Item.visible.each do |i|
      too_long_item_ids << i.id if i.recursive_parent_count > 2
    end
    return too_long_item_ids
  end
  
  def self.get_too_long_child_recursion_ids # Item.get_too_long_child_recursion_ids
    too_long_item_ids = []
    Item.visible.each do |i|
      too_long_item_ids << i.id if i.recursive_child_count > 2
    end
    return too_long_item_ids
  end
  
  def self.get_child_duplicate_ids # Item.get_child_duplicate_ids
    duplicate_array = Vendor.connection.execute("SELECT child_id, count(*) FROM items WHERE hidden IS NULL AND child_id IS NOT NULL AND child_id != 0 GROUP BY child_id HAVING count(*) > 1").to_a
    
    info = duplicate_array.collect {|d| [d[0], Item.visible.where(:child_id => d[0]).collect {|i| i.id }] }
    
    #puts "Duplicates: #{ info.inspect }"
    duplicate_ids = duplicate_array.collect { |x| x[0] }
    duplicate_ids.delete(nil)
    duplicate_ids.delete(0)
    return info
  end
  
  def self.get_duplicate_names # Item.get_duplicate_names
    duplicate_array = Vendor.connection.execute("SELECT name, count(*) FROM items WHERE hidden IS NULL GROUP BY name HAVING count(*) > 1").to_a
  end

  # duplicate_array = Vendor.connection.execute("SELECT id, sku, count(*) FROM items WHERE hidden IS NULL OR hidden IS FALSE GROUP BY sku HAVING count(*) > 1").to_a
  def self.get_sku_duplicate_ids # Item.get_sku_duplicate_ids
    duplicate_array = Vendor.connection.execute("SELECT id, count(*) FROM items WHERE hidden IS NULL OR hidden IS FALSE GROUP BY sku HAVING count(*) > 1").to_a
    #puts "Duplicates: #{ duplicate_array.inspect }"
    duplicate_ids = duplicate_array.collect { |x| x[0] }
    return duplicate_ids
  end
  
  def self.get_nonhidden_items_with_hidden_child_ids # Item.get_nonhidden_items_with_hidden_child_ids
    ids = []
    # get all parents
    Item.visible.where("child_id IS NOT NULL").each do |i|
      ids << i.id if i.child and i.child.hidden == true
    end
    return ids
  end
  
  def self.get_nonhidden_items_with_hidden_parent_ids # Item.get_nonhidden_items_with_hidden_parent_ids
    ids = []
    Item.visible.each do |i|
      ids << i.id if i.parent and i.parent.hidden == true
    end
    return ids
  end
  
  # cleaning methods
  
  def self.clean_zero_child
    ids = self.get_zero_child_ids
    Item.where(:id => ids).update_all :child_id => nil
  end

  def self.clean_self_loops
    ids = self.get_self_loop_ids
    items = Item.where(:id => ids)
    items.each { |i| i.hide(-20) }
    return ids
  end
  
  def self.clean_duplicates
    ids = self.get_sku_duplicate_ids
    items = Item.where(:id => ids)
    items.each { |i| i.hide(-21) }
    return ids
  end

  def self.clean_nonhidden_items_with_hidden_child # Item.clean_get_nonhidden_items_with_hidden_child
    ids = self.get_nonhidden_items_with_hidden_child_ids
    ids.each do |id|
      item = Item.find(id)
      item.child_id = nil
      item.save!
    end
    return ids
  end
  
  def self.clean_nonhidden_items_with_hidden_parent # Item.clean_get_nonhidden_items_with_hidden_parent
    Item.where(:hidden => true).update_all :child_id => nil
#     ids = self.get_nonhidden_items_with_hidden_parent_ids
#     ids.each do |id|
#       item = Item.find(id)
#       item.parent = nil
#       #item.save!
#     end
#     return ids
  end
  
  def self.clean_child_duplicates # Item.clean_child_duplicates
    deletable_ids = []
    array = get_child_duplicate_ids
    array.each do |a|
      item_ids = a[1]
      item_ids.each do |i|
        any_sales = OrderItem.visible.where(:item_id => i).any?
        any_inventory = InventoryReportItem.where(:item_id => i).any?
        deletable = any_sales == false && any_inventory == false
        deletable_ids << i if deletable
      end
    end
    Item.where(:id => deletable_ids).each {|i| i.hide(-24) }
    return deletable_ids 
  end
  
  def self.clean_too_long_chains # Item.clean_too_long_chains
    ids = self.get_too_long_parent_recursion_ids
    ids.each do |id|
      item = Item.find(id)
      parent_skus = item.recursive_parent_sku_chain
      parent_skus.each do |psku|
        i = Item.find_by_sku(psku)
        i.unlink
      end
    end
    ids = self.get_too_long_child_recursion_ids
    ids.each do |id|
      item = Item.find(id)
      child_skus = item.recursive_child_sku_chain
      child_skus.each do |csku|
        i = Item.find_by_sku(csku)
        i.unlink
      end
    end
  end
  
  def self.run_diagnostics # Item.run_diagnostics
    cd = self.get_child_duplicate_ids
    sd = self.get_sku_duplicate_ids
    sl = self.get_self_loop_ids
    tlpr = self.get_too_long_parent_recursion_ids
    tlcr = self.get_too_long_child_recursion_ids
    nhihc = self.get_nonhidden_items_with_hidden_child_ids
    nhihp = self.get_nonhidden_items_with_hidden_parent_ids
    
    result = {}
    result[:child_duplicates] = cd
    result[:sku_duplicates] = sd
    result[:self_loops] = sl
    result[:too_long_parent_recursion] = tlpr
    result[:too_long_child_recursion] = tlcr
    result[:hidden_child] = nhihc
    result[:hidden_parent] = nhihp
    
    status = ! (cd.any? || sd.any? || sl.any? || tlpr.any? || tlcr.any? || nhihc.any? || nhihp.any?)
    #status = false # for email testing
    
    return {:status => status, :result => result}
  end
  
  # This is the main method that should be used to transact a quantity of an Item. Transactions are safer and more transparent than setting the "quantity" attribute directly, so this should be used. This method also takes care of recursion of parent/child items as well as Items with many StockItem in many locations. "diff" is the amount that will be transacted for the Item "item". "model2" is just for labeling purposes of StockTransactions and can be of any class that can logially send or receive quantities (e.g. StockItem, Item, ShipmentItem, Order, etc.). If "item" does not have any StockItems defined, the simple quantity attribute will used instead for backwards-compatibility.
  def self.transact_quantity(diff, item, model2)
    Item.transact_quantity_with_recursion(diff, item, model2)
  end

  private
  
  # This method adds or subtracts "diff" from the total stock quantity of "item". If "diff" is such that the quantity of "item" would go into negative, it recursively takes stock from the parents of "item" until the demand is satisfied. If "diff" is positive or non-integer or there is no parent of "item", no recursion takes place, it set the quantity of "item" directly. "model2" is just for labeling purposes for the StockTransactions that will be created further down. "model2" can be of class Item or class Order. When an order is completed on the POS screen, "model2" will be an Order. This means that the StockTransaction will show that the stock has been moved into an Order (i.e. was sold and moved out of the store), rather than into a StockItem/Location (i.e. within the store).
  def self.transact_quantity_with_recursion(diff, item, model2, depth=0)
    SalorBase.log_action "[RECURSION]", " [#{ item.sku }] Called with diff = #{ diff.to_f }", :light_blue
    depth += 1
    raise "Item.set_quantity_recursively: Cap of 5 reached." if depth > 5
    
    diff = 0 if diff.blank?
    diff = diff.to_s.gsub(',','.')
    diff = diff.to_f.round(3)
    parent = item.parent
    
    quantity_total = item.quantity_with_stock
    
    # q is the quantity that would be there after "diff" has been added to the current quantity.
    q = quantity_total + diff
    
    if (q >= 0 or        # no recursion needed if zero or positive
        q != q.round or  # no recursion for non-integers
        quantity_total != quantity_total.round or # no recursion for non-integers
        (parent.nil?) # no recursion if no parent
       )
      SalorBase.log_action "[RECURSION]", "[#{ item.sku }] No recursion. Making a stock transaction with diff=#{ diff.to_f } directly.", :light_blue
      Item.transact_quantity_with_stock(diff, item, model2)
      return
    end

    parent_units_needed = ( -q / parent.packaging_unit ).ceil
    SalorBase.log_action "[RECURSION]", "[#{ item.sku }] parent_units_needed=#{ parent_units_needed }", :light_blue
    
    quantity_from_parent = parent_units_needed * parent.packaging_unit
    SalorBase.log_action "[RECURSION]", " [#{ item.sku }] getting quantity_from_parent=#{ quantity_from_parent }", :light_blue
    Item.transact_quantity_with_stock(quantity_from_parent, item, parent)
    
    SalorBase.log_action "[RECURSION]", " [#{ item.sku }] Now that we have taken from the parent, we create a stock transaction with diff=#{ diff }, which is the quantity acutally requested", :light_blue
    Item.transact_quantity_with_stock(diff, item, model2)
    
    # now we need to reduce the quantity of the parent. this starts the recursion
    SalorBase.log_action "[RECURSION]", "[#{ item.sku }] Now that we have taken from the parent, reduce the quantity of the parent by #{ - parent_units_needed }. This starts recursion.", :light_blue
    Item.transact_quantity_with_recursion(-parent_units_needed, parent, item, depth)
  end
  
  
  
  
  # This method creates stock transactiond of the size "diff" for "item". If "diff" is positive, the first ItemStock that is defined for "item" is used to add "diff". If "diff" is negative, this method will iterate over all defined ItemStocks of "item" and reduce every one until the reduced amount equals "diff". If "diff" is larger than the quantity available in all ItemStocks, it reduces the first ItemStock into negative, so that "diff" is satisfied. "model2" is just there for reference purposes, to label the StockTransactions that will be created further down.
  def self.transact_quantity_with_stock(diff, item, model2)
    item_stocks = item.item_stocks.visible.order("location_type ASC")
    
    if item_stocks.blank?
      # use the simple quantity field of Item when no ItemStocks are defined.
      StockTransaction.transact(diff, item, model2)
      return
    end
      

    if diff > 0
      SalorBase.log_action "[Item]", "transact_quantity_with_stock=() difference is positive #{ diff }.", :magenta
      item_stock = item_stocks.first
      if model2.class == Item
        model2_item_stocks = model2.item_stocks.visible
        model2_item_stock = model2_item_stocks.first
      end
      StockTransaction.transact(diff, item_stock, model2_item_stock)


    elsif diff < 0
      SalorBase.log_action "[Item]", "transact_quantity_with_stock=() difference is negative #{ diff }.", :magenta
      
      # this method gets the quantity total of all ItemStocks
      quantity_total = item.quantity_with_stock
      SalorBase.log_action "[Item]", "transact_quantity_with_stock=(): quantity_total = #{ quantity_total }", :magenta
      # First, we take from all ItemStocks which belong to a Location, as much as we can get (not reducing location_quantity below zero). If we still don't have enough, then we do the same for all ItemStocks which belong to a StockLocation. If we still don't have enough, we reduce the location_quantity of the first ItemStock which belongs to a Location to below zero. This maps approximately what happens in a store.
      
      amount_to_go = - diff
      SalorBase.log_action "[Item]", "transact_quantity_with_stock=(): subtraction: amount_to_go =  #{ amount_to_go }", :magenta
      
      
      item_stocks.each do |is|
        SalorBase.log_action "[Item]", "transact_quantity_with_stock=(): looping through all item_stocks of #{ item.class } #{ item.id }: ItemStock #{ is.id}. amount_to_go is #{ amount_to_go } ", :magenta
        # we break this loop when we got enough
        break if amount_to_go == 0
        
        if (amount_to_go < 0)
          # just a security measure.
          raise "This method has taken more than it should have. Rounding errors?"
        end
        
        available_quantity = is.quantity
        if available_quantity == 0
          SalorBase.log_action "[Item]", "transact_quantity_with_stock=(): this ItemStock #{ is.id } is zero. nothing to take from here.", :magenta
          
        elsif available_quantity - amount_to_go >= 0
          SalorBase.log_action "[Item]", "transact_quantity_with_stock=(): this ItemStock #{ is.id } has enough quantity to cover our demand. Creating StockTransaction with diff #{ -amount_to_go }", :magenta
          StockTransaction.transact(-amount_to_go, is, model2)
          amount_to_go = 0
          
        elsif available_quantity - amount_to_go < 0
          SalorBase.log_action "[Item]", "transact_quantity_with_stock=(): this ItemStock #{ is.id } does not have enough quantity to cover our demand. subtracting everything (#{ is.quantity }).", :magenta
          # this ItemStock does not have enough quantity to cover our demand. We still take what we can get, don't take more than available, and rememeber how much we have taken.
          amount_to_go -= is.quantity
          StockTransaction.transact(-is.quantity, is, model2)
        end
      end
      
      if amount_to_go > 0
        # looping through all ItemStocks hasn't satisfied our demand, so we have to force the first of the  ItemStocks into negative quantity
        item_stock = item_stocks.visible.first
        StockTransaction.transact(-amount_to_go, item_stock, model2)
        SalorBase.log_action "[Item]", "transact_quantity_with_stock=(): looping through all ItemStocks hasn't satisfied our demand, so we have to force the first of the ItemStocks into negative quantity. setting ItemStock #{ item_stock.id } to #{ -amount_to_go }.", :magenta
      end

    else
      SalorBase.log_action "[Item]", "transact_quantity_with_stock=(): difference is zero, nothing to do", :magenta
    end
    
  end

end
