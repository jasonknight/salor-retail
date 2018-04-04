# coding: UTF-8

# Copyright (c) 2012 Red (E) Tools Ltd.
#
# Permission is hereby granted, free of charge, to any person obtaining a 
# copy of this software and associated documentation files (the "Software"), 
# to deal in the Software without restriction, including without limitation 
# the rights to use, copy, modify, merge, publish, distribute, sublicense, 
# and/or sell copies of the Software, and to permit persons to whom the 
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included 
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS 
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR 
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, 
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR 
# OTHER DEALINGS IN THE SOFTWARE.


# =====================================
# DANGER: DO NOT REMOVE OR DISABLE THIS CODE BLOCK
if User.any? or Item.any? or Company.any? or Order.any? or OrderItem.any?
  puts "Database is already seeded. Danger of overwriting database records. Not running seed script again."
  Process.exit 0
end
# =====================================

company_count = 0

countries = ['us','at','fr','es','el','ru','it','cn', 'hr', 'ca', 'nl']
languages = ['en','gn','fr','es','el','ru','it','cn', 'hr', 'en', 'nl']
currencies = ['USD', 'EUR', 'EUR', 'EUR', 'EUR', 'RUB', 'EUR', 'CNY', 'EUR', 'CAD', 'NLG']
company_count = 1


actions_to_create = [
  {
    :name => 'Add price', 
    :whento => :add_to_order, 
    :behavior => :add,
    :afield => :price_cents,
    :value => 100 # i.e.  1 dollar
  },
  {
    :name => 'Multiply price', 
    :whento => :add_to_order, 
    :behavior => :multiply,
    :afield => :price_cents,
    :value => 2 # i.e.  double the price
  },
  {
    :name => 'Multiply quantity', 
    :whento => :add_to_order, 
    :behavior => :multiply,
    :afield => :quantity,
    :value => 5 # i.e.  make the quantity 5 for instances of a unit that is always sold as a set from cigarman
  },
  {
    :name => 'Divide price', 
    :whento => :add_to_order, 
    :behavior => :divide,
    :afield => :price_cents,
    :value => 5 # i.e.  sometimes a unit price is the carton price
  },
  {
    :name => 'B6G6 for SKU', 
    :whento => :change_quantity, 
    :behavior => :discount_after_threshold,
    :afield => nil,
    :value => 1, # i.e. 100% discount
    :value2 => 5 # i.e. must buy 5 items to receive the discount, the 6th will trigger the action
  },
  {
    :name => 'B5G6 for Category ADD', 
    :whento => :add_to_order, 
    :behavior => :discount_after_threshold,
    :afield => nil,
    :value => 1, # i.e. 100% discount
    :value2 => 5 # i.e. must buy 5 items to receive the discount, the 6th will trigger the action
  },
  {
   :name => 'B5G6 for Category INCREMENT', 
   :whento => :change_quantity, 
   :behavior => :discount_after_threshold,
   :afield => nil,
   :value => 1, # i.e. 100% discount
   :value2 => 5 # i.e. must buy 5 items to receive the discount, the 6th will trigger the action
   },
  {
    :name => 'Execute JS code', 
    :whento => :add_to_order, 
    :behavior => :execute,
    :afield => :price_cents,
    :js_code => %Q[api.update_attributes({ price_cents: 1095 });]
  }
  
]

# we create 3 different tax amounts because that is usual in some countries and we need it to test
tax_percentages = [20, 10, 0]
tax_profile_letters = ['A', 'B', 'C']
tax_profile_defaults = [nil, true, nil]

role_names = [:manager, :head_cashier, :cashier, :stockboy, :assistant]

invoice_blurb_languages = ['en', 'gn']
invoice_blurb_texts = {}
invoice_blurb_texts['en'] = [ 'header line', 'footer line' ]
invoice_blurb_texts['gn'] = [ 'Kofpzeile', 'Fußzeile' ]
invoice_blurb_invoiceaddon = {}
invoice_blurb_invoiceaddon['en'] = ' with Kramdown **formatted** text'
invoice_blurb_invoiceaddon['gn'] = ' mit Kramdown **formatiertem** text'

payment_method_names = ['Cash', 'Card','Unpaid','Quote','Change']
payment_methods_cash = [true, nil, nil, nil, nil]
payment_methods_change = [nil, nil, nil, nil, true]
payment_methods_quote = [nil, nil, nil, true, nil]
payment_methods_unpaid = [nil, nil, true, nil, nil]

country_names = ['USA', 'Europe']

item_type_behaviors = ['normal', 'gift_card', 'coupon', 'aconto']
item_type_names = ['Normal Item', 'Gift Card', 'Coupon', 'a conto']

shipment_types_names = ['planning', 'ordered', 'delayed', 'delivered', 'processed']

transaction_tag_names = ['safe','bank','taxi','cleaning','other']

sale_type_names = ['online service', 'hardware', 'mixed']

cash_register_names = ['Local', 'Remote']
cash_register_salor_printer = [nil, true]


company_count.times do |c|
  company = Company.new
  company.name = "Company#{ c }"
  company.identifier = c
  company.full_subdomain = '' # for development testing SrSaas on localhost:3000
  r = company.save!
  puts "\n\n =========\nCOMPANY #{ c } created\n\n" if r == true
  
  countries.size.times do |v|
    
    special_item_objects = []

    # variables we will use for actions
    the_button_category = nil

    vendor = Vendor.new
    vendor.name = "Vendor#{ c }#{ v }"
    vendor.country = countries[v]
    vendor.currency = currencies[v]
    vendor.company = company
    vendor.identifier = "vendor#{c}#{v}"
    vendor.time_zone = "Paris"
    r = vendor.save!
    puts "\n---------\nVENDOR #{ c } #{ v } created\n" if r == true
    ## raise "ERROR: #{ vendor.errors.messages }" if r == false
    
    
    item_type_objects = []
    item_type_behaviors.size.times do |i|
      it = ItemType.new
      it.company = company
      it.vendor = vendor
      it.name = item_type_names[i]
      it.behavior = item_type_behaviors[i]
      r = it.save!
      item_type_objects << it
      puts "ItemType #{ c } #{ v } created" if r == true
      ## raise "ERROR: #{ it.errors.messages }" if r == false
    end
    
    payment_method_objects = []
    payment_method_names.size.times do |i|
      pm = PaymentMethod.new
      pm.vendor = vendor
      pm.company = company
      pm.name = "#{payment_method_names[i]}#{ c }#{ v }"
      pm.cash = payment_methods_cash[i]
      pm.change = payment_methods_change[i]
      pm.quote = payment_methods_quote[i]
      pm.unpaid = payment_methods_unpaid[i]
      pm.save!
      payment_method_objects << pm
      puts "PaymentMethod #{ c } #{ v } created"
    end
    
    cash_register_objects = []
    cash_register_names.size.times do |i|
      cr = CashRegister.new
      cr.name = "#{ cash_register_names[i] }#{ c }#{ v }"
      cr.vendor = vendor
      cr.company = company
      cr.detailed_edit = true
      cr.salor_printer = cash_register_salor_printer[i]
      r = cr.save!
      cash_register_objects << cr
      puts "CashRegister #{ cr.name } created" if r == true
      ## raise "ERROR: #{ cr.errors.messages }" if r == false
    end
    
    role_objects = []
    role_names.size.times do |i|
      r = Role.new
      r.company = company
      r.vendor = vendor
      r.name = "#{ role_names[i] }"
      r.save!
      role_objects << r
      puts "Role #{ r.name } created"
    end
    
    user_objects = []
    role_objects.size.times do |i|
      u = User.new
      u.company = company
      u.vendors << vendor
      u.roles = [role_objects[i]]
      u.password = "#{ c }#{ v }#{ i }"
      u.username = "#{ role_names[i] }#{ c }#{ v }"
      u.language = languages[v]
      u.save!
      user_objects << u
      puts "User #{ u.username } with password #{ c }#{ v }#{ i } created."
      u.set_drawer
    end
    
    tax_profile_objects = []
    tax_percentages.size.times do |i|
      tp = TaxProfile.new
      tp.company = company
      tp.vendor = vendor
      tp.name = "#{ tax_percentages[i] }%"
      tp.value = tax_percentages[i]
      tp.default = tax_profile_defaults[i]
      tp.letter = tax_profile_letters[i]
      tp.save!
      tax_profile_objects << tp
      puts "TaxProfile #{ tp.name } created"
    end
    
    category_objects = []
    3.times do |i|
      cat = Category.new
      cat.company = company
      cat.vendor = vendor
      cat.name = "Category #{ c }#{ v }#{ i }"
      cat.save!
      category_objects << cat
      puts "Category #{ cat.name } created"
    end

    # Create the B5G6 Category
    b5g6_category = Category.new
    b5g6_category.company = company
    b5g6_category.vendor = vendor
    b5g6_category.name = "B5G6"
    b5g6_category.save!
    
    # create a special button category for special items
    special_cat = Category.new
    special_cat.company = company
    special_cat.vendor = vendor
    special_cat.name = "Specials"
    special_cat.button_category = true
    special_cat.save!
    category_objects << special_cat
    puts "Special Category #{ special_cat.name } created"
    
    button_category_objects = []
    3.times do |i|
      cat = Category.new
      cat.company = company
      cat.vendor = vendor
      cat.name = "Button Cat #{ c }#{ v }#{ i }"
      cat.button_category = true
      cat.save!
      button_category_objects << cat
      puts "ButtonCategory #{ cat.name } created"
    end

    the_button_category = button_category_objects.last

    action_num = 0
    actions_to_create.each do |attrs|
      action = Action.new
      action.company = company
      action.vendor = vendor
      action.attributes = attrs
      # create an item for this action
      if attrs[:name].include? "B5G6 for Category"
        action.model = b5g6_category
      end
      action.save!

      unless attrs[:name].include? "B5G6 for Category"
        # create test item for this action. b5g6 test items will be created below
        item = Item.new
        item.company = company
        item.vendor = vendor
        item.tax_profile = tax_profile_objects.last
        item.sku = "ACTION#{ action_num }"
        item.category = category_objects.first # we don't want this to be the thresh category
        item.name = "Item for Action '#{ attrs[:name] }'"
        item.price_cents = 1000
        item.item_type = item_type_objects[0]
        item.currency = currencies[v]
        item.save!
        action.model = item
        special_item_objects << item
      end
        
      action_num += 1
    end
    
    # create 3 test items for b5g6 action
    thr_prices = [ 100, 200, 300 ]
    3.times do |thr_i|
      item = Item.new
      item.company = company
      item.vendor = vendor
      item.tax_profile = tax_profile_objects.first
      item.category = b5g6_category
      item.sku = "THR#{ thr_i }"
      item.name = "Item #{ thr_i } for B5G6"
      item.price_cents = thr_prices[thr_i] # choose a price at random
      # this is because thresh items are supposed to discount the min price of the group!
      item.item_type = item_type_objects[0]
      item.currency = currencies[v]
      item.save!
      special_item_objects << item
    end
    
    item_objects = []
    category_objects.size.times do |i|
      5.times do |j|
        k = j % 3
        item = Item.new
        item.company = company
        item.vendor = vendor
        item.tax_profile = tax_profile_objects[k]
        item.category = category_objects[i]
        item.sku = "SKU#{ i }#{ j }"
        item.name = "Test Item #{ i }#{ j }"
        item.price_cents = 100 * (10 * i + j + 1)
        item.item_type = item_type_objects[0]
        item.currency = currencies[v]
        item.save!
        item_objects << item
        puts "Item #{ item.sku } created"
      end
    end


    
    

    
    # for recursion test
    recursion_item_names = ['piece', 'pack', 'carton']
    recursion_item_names = ['PIECE', 'PACK', 'CARTON']
    recursion_item_packaging_units = [1, 20, 10]
    recursion_item_prices = [20, 400, 4000]
    recursion_item_quantities = [0, 50, 20]
    previous_item = nil
    recursion_item_names.size.times do |i|
      item = Item.new
      item.company = company
      item.vendor = vendor
      item.tax_profile = tax_profile_objects[0]
      item.category = special_cat
      item.sku = recursion_item_names[i]
      item.name = recursion_item_names[i]
      item.packaging_unit = recursion_item_packaging_units[i]
      item.price_cents = recursion_item_prices[i]
      item.item_type = item_type_objects[0]
      item.currency = currencies[v]
      item.child = previous_item
      item.quantity = recursion_item_quantities[i]
      item.save!
      puts "Test Recursion Item #{ c } #{ v } #{ i } created"
      previous_item = item
      special_item_objects << item
    end
    
    # create an "immediate weighing" item
    item = Item.new
    item.company = company
    item.vendor = vendor
    item.tax_profile = tax_profile_objects[1]
    item.category = special_cat
    item.sku = "WEIGHITEM"
    item.name = "Immediate weighing"
    item.item_type = item_type_objects[0]
    item.currency = currencies[v]
    item.weigh_compulsory = true
    item.price_cents = 100
    item.save!
    puts "Immediate Weighing Item #{ c } #{ v } created"
    
    special_item_objects << item
    
    # create an "must change price" item
    item = Item.new
    item.company = company
    item.vendor = vendor
    item.tax_profile = tax_profile_objects[1]
    item.category = special_cat
    item.sku = "MUSTCHANGEPRICE"
    item.name = "Must change price"
    item.item_type = item_type_objects[0]
    item.currency = currencies[v]
    item.must_change_price = true
    item.price_cents = 0
    item.save!
    puts "Must Change Price Item #{ c } #{ v } created"
    special_item_objects << item
    
    # create an "default buyback" item
    item = Item.new
    item.company = company
    item.vendor = vendor
    item.tax_profile = tax_profile_objects[1]
    item.category = special_cat
    item.sku = "DEFAULTBUYBACK"
    item.name = "Default Buyback"
    item.item_type = item_type_objects[0]
    item.currency = currencies[v]
    item.default_buyback = true
    item.price_cents = 200
    item.buy_price_cents = 100
    item.save!
    puts "Default Buyback Item #{ c } #{ v } created"
    special_item_objects << item
    
    # create an "default buyback + must change price" item
    item = Item.new
    item.company = company
    item.vendor = vendor
    item.tax_profile = tax_profile_objects[1]
    item.category = special_cat
    item.sku = "BUYBACKCHANGEPRICE"
    item.name = "Buyback + Must change price"
    item.item_type = item_type_objects[0]
    item.currency = currencies[v]
    item.default_buyback = true
    item.must_change_price = true
    item.buy_price_cents = 0
    item.buy_price_cents = 0
    item.save!
    puts "Default Buyback+MustChangePrice Item #{ c } #{ v } created"
    special_item_objects << item
    
    # create dynamic giftcard item
    zero_tax_profile = vendor.tax_profiles.visible.find_by_value(0)
    gift_card_item_type = vendor.item_types.visible.find_by_behavior('gift_card')
    item = Item.new
    item.company = company
    item.vendor = vendor
    item.tax_profile = zero_tax_profile
    item.category = special_cat
    item.sku = "G000000000000"
    item.name = "Dynamic Gift Card"
    item.item_type = gift_card_item_type
    item.currency = currencies[v]
    item.save!
    
    puts "Dynamic Gift Card Item #{ c } #{ v } created"
    
    special_item_objects << item
    
    # create special DMYACONTO item
    zero_tax_profile = vendor.tax_profiles.visible.find_by_value(0)
    aconto_item_type = vendor.item_types.visible.find_by_behavior('aconto')
    item = Item.new
    item.company = company
    item.vendor = vendor
    item.tax_profile = zero_tax_profile
    item.sku = "DMYACONTO"
    item.name = "On account"
    item.item_type = aconto_item_type
    item.currency = currencies[v]
    item.save!
    
    puts "Special Item 'On Account' DMYACONTO #{ c } #{ v } created"
    
    # create test coupon items
    coupon_types = [1, 2, 3] # 1=percent, 2=fixed, 3=buyonegetone
    coupon_amounts = [1000, 50, 0]
    coupon_descriptions = ["10%", "50c off", "b1g1"]
    zero_tax_profile = vendor.tax_profiles.visible.find_by_value(0)
    coupon_item_type = vendor.item_types.visible.find_by_behavior('coupon')
    coupon_types.size.times do |i|
      item = Item.new
      item.company = company
      item.vendor = vendor
      item.tax_profile = zero_tax_profile
      item.category = special_cat
      item.item_type = coupon_item_type
      item.sku = "TESTCOUPON#{i}"
      item.name = "#{ coupon_descriptions[i] } Coupon for #{ item_objects[4].sku }"
      item.coupon_applies = item_objects[4].sku
      item.coupon_type = coupon_types[i]
      item.price_cents = coupon_amounts[i]
      item.currency = currencies[v]
      item.save!
     
      puts "Test Coupon Item #{ coupon_descriptions[i] } #{ c } #{ v } created"
      
      special_item_objects << item
    end
    
    location_objects = []
    3.times do |i|
      l = Location.new
      l.vendor = vendor
      l.company = company
      l.name = "Location#{ c }#{ v }#{ i }"
      l.save!
      location_objects << l
      puts "#{ l.name } created"
    end
    
    stock_location_objects = []
    3.times do |i|
      l = StockLocation.new
      l.vendor = vendor
      l.company = company
      l.name = "StockLocation#{ c }#{ v }#{ i }"
      res = l.save!
      stock_location_objects << l
      puts "#{ l.name } created"
    end
    
    broken_item_objects = []
    3.times do |i|
      b = BrokenItem.new
      b.vendor = vendor
      b.company = company
      b.name = "BrokenItem#{ c }#{ v }#{ i }"
      b.sku = "BI#{ c }#{ v }#{ i }"
      b.quantity = i
      b.currency = currencies[v]
      b.save!
      broken_item_objects << b
      puts "#{ b.name } created"
    end
    
    # Create test discount
    discount_objects = []
    d = Discount.new
    d.vendor = vendor
    d.company = company
    d.name = "Test Discount for Item SKU #{ item_objects[2].sku }"
    d.start_date = 1.week.ago
    d.end_date = Time.now + 1.week
    d.applies_to = "Item"
    d.item_sku = item_objects[2].sku
    d.amount = 10
    d.amount_type = 'percent'
    d.save!
    discount_objects << d
    puts "#{ d.name } created"
    
    
    shipment_type_objects = []
    shipment_types_names.size.times do |i|
      st = ShipmentType.new
      st.vendor = vendor
      st.company = company
      st.name = "#{ shipment_types_names[i] }#{ c }#{ v }"
      st.save!
      shipment_type_objects << st
      puts "#{ st.name } created"
    end
    
    shipper_objects = []
    3.times do |i|
      s = Shipper.new
      s.vendor = vendor
      s.company = company
      s.name = "Shipper#{ c }#{ v }#{ i }"
      s.save!
      shipper_objects << s
      puts "#{ s.name } created"
    end
    
    customer_objects = []
    3.times do |i|
      cu = Customer.new
      cu.vendor = vendor
      cu.company = company
      cu.first_name = "Bob"
      cu.last_name = "Doe#{ c }#{ v }#{ i }"

      lc = LoyaltyCard.new
      lc.vendor = vendor
      lc.company = company
      lc.sku = "LC#{ c }#{ v }#{ i }"
      lc.save!
      
      cu.loyalty_cards << lc
      cu.save!
      customer_objects << cu
      
      puts "#{ cu.first_name } #{ cu.last_name } created"
    end
    
    transaction_tag_objects = []
    transaction_tag_names.size.times do |i|
      tt = TransactionTag.new
      tt.vendor = vendor
      tt.company = company
      tt.name = "#{ transaction_tag_names[i] }#{ c }#{ v }"
      tt.save!
      transaction_tag_objects << tt
      puts "#{ tt.name } created"
    end
    
    country_objects = []
    country_names.size.times do |i|
      co = Country.new
      co.vendor = vendor
      co.company = company
      co.name = "#{ country_names[i] }#{ c }#{ v }"
      co.save!
      country_objects << co
      puts "#{ co.name } created"
    end
    
    sale_type_objects = []
    sale_type_names.size.times do |i|
      st = SaleType.new
      st.vendor = vendor
      st.company = company
      st.name = "#{ sale_type_names[i] }#{ c }#{ v }"
      st.save!
      sale_type_objects << st
      puts "#{ st.name } created"
    end
    
    button_objects = []
    button_category_objects.size.times do |i|
      3.times do |j|
        item_index = 3 * i + j
        b = Button.new
        b.vendor = vendor
        b.company = company
        b.sku = item_objects[item_index].sku
        b.category = button_category_objects[i]
        b.name = item_objects[item_index].name
        b.save!
        button_objects << b
        puts "#{ b.name } created"
      end
    end
    
    special_item_objects.size.times.each do |i|
      b = Button.new
      b.vendor = vendor
      b.company = company
      b.sku = special_item_objects[i].sku
      b.category = special_cat
      b.name = special_item_objects[i].name
      b.save!
      button_objects << b
      puts "#{ b.name } created"
    end
    
    invoice_blurb_objects = []
    invoice_blurb_languages.size.times do |i|
      2.times do |j|
        ib = InvoiceBlurb.new
        ib.vendor = vendor
        ib.company = company
        ib.lang = invoice_blurb_languages[i]
        ib.body = invoice_blurb_texts[invoice_blurb_languages[i]][j] + invoice_blurb_invoiceaddon[invoice_blurb_languages[i]]
        ib.body_receipt = invoice_blurb_texts[invoice_blurb_languages[i]][j]
        ib.is_header = j.zero?
        ib.save!
        invoice_blurb_objects << ib
        puts "InvoiceBlurb #{ ib.body } created"
      end
    end
    
    invoice_note_objects = []
    country_objects.size.times do |i|
      country_objects.size.times do |j|
        sale_type_objects.size.times do |k|
          ivn = InvoiceNote.new
          ivn.vendor = vendor
          ivn.company = company
          ivn.note_header = "Header note for sales from #{ country_objects[i].name } to #{ country_objects[j].name } of SaleType #{ sale_type_objects[k].name }. Kramdown **formatted**."
          ivn.note_footer = "Footer note for sales from #{ country_objects[i].name } to #{ country_objects[j].name } of SaleType #{ sale_type_objects[k].name }. Kramdown **formatted**."
          ivn.origin_country = country_objects[i]
          ivn.destination_country = country_objects[j]
          ivn.sale_type = sale_type_objects[k]
          ivn.name = "sales from #{ country_objects[i].name } to #{ country_objects[j].name } of SaleType #{ sale_type_objects[k].name }"
          ivn.save!
          invoice_note_objects << ivn
          puts "InvoiceNote #{ ivn.name } created"
        end
      end
    end
  end
end