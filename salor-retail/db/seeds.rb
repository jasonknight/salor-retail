# coding: UTF-8

# Copyright (c) 2012 Red (E) Tools Ltd.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


if User.any?
  puts "Database is already seeded. Danger of overwriting database records. Not running seed script again."
  Process.exit 0
end


# WARNING: Uncommenting the following will destroy all data!
# ActiveRecord::Base.connection.tables.each do |t|      
#   begin
#     model = t.classify.constantize
#     model.reset_column_information
#   rescue
#     next
#   end
#   puts "Purging table #{ model }"
#   model.delete_all
# end

company_count = 0

# if ENV['SEED_MODE'] == 'full'
  puts "SEED_MODE is 'full'"
  countries = ['us','at','fr','es','el','ru','it','cn']
  languages = ['en','gn','fr','es','el','ru','it','cn']
  company_count = 1
# else
#   puts "SEED_MODE is 'minimal'"
#   countries = ['us']
#   languages = ['en']
#   company_count = 1
# end

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

item_type_behaviors = ['normal', 'gift_card', 'coupon']
item_type_names = ['Normal Item', 'Gift Card', 'Coupon']

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
  r = company.save
  puts "\n\n =========\nCOMPANY #{ c } created\n\n" if r == true
  
  countries.size.times do |v|
    vendor = Vendor.new
    vendor.name = "Vendor#{ c }#{ v }"
    vendor.country = countries[v]
    vendor.company = company
    vendor.identifier = "vendor#{c}#{v}"
    r = vendor.save
    puts "\n---------\nVENDOR #{ c } #{ v } created\n" if r == true
    raise "ERROR: #{ vendor.errors.messages }" if r == false
    
    
    item_type_objects = []
    item_type_behaviors.size.times do |i|
      it = ItemType.new
      it.company = company
      it.vendor = vendor
      it.name = "#{ item_type_names[i] }#{ c }#{ v }"
      it.behavior = item_type_behaviors[i]
      r = it.save
      item_type_objects << it
      puts "ItemType #{ c } #{ v } created" if r == true
      raise "ERROR: #{ it.errors.messages }" if r == false
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
      res = pm.save
      payment_method_objects << pm
      puts "PaymentMethod #{ c } #{ v } created" if res == true
      raise "ERROR: #{ pm.errors.messages }" if res == false
    end
    
    cash_register_objects = []
    cash_register_names.size.times do |i|
      cr = CashRegister.new
      cr.name = "#{ cash_register_names[i] }#{ c }#{ v }"
      cr.vendor = vendor
      cr.company = company
      cr.salor_printer = cash_register_salor_printer[i]
      r = cr.save
      cash_register_objects << cr
      puts "CashRegister #{ cr.name } created" if r == true
      raise "ERROR: #{ cr.errors.messages }" if r == false
    end
    
    role_objects = []
    role_names.size.times do |i|
      r = Role.new
      r.company = company
      r.vendor = vendor
      r.name = "#{ role_names[i] }"
      res = r.save
      role_objects << r
      puts "Role #{ r.name } created" if res == true
      raise "ERROR: #{ r.errors.messages }" if res == false
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
      res = u.save
      user_objects << u
      puts "User #{ u.username } with password #{ c }#{ v }#{ i } created. Drawer is #{ u.drawer_id }" if res == true
      raise "ERROR: #{ u.errors.messages }" if res == false
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
      res = tp.save
      tax_profile_objects << tp
      puts "TaxProfile #{ tp.name } created" if res == true
      raise "ERROR: #{ tp.errors.messages }" if res == false
    end
    
    category_objects = []
    3.times do |i|
      cat = Category.new
      cat.company = company
      cat.vendor = vendor
      cat.name = "Category#{ c }#{ v }#{ i }"
      res = cat.save
      category_objects << cat
      puts "Category #{ cat.name } created" if res == true
      raise "ERROR: #{ cat.errors.messages }" if res == false
    end
    
    button_category_objects = []
    3.times do |i|
      cat = Category.new
      cat.company = company
      cat.vendor = vendor
      cat.name = "Category#{ c }#{ v }#{ i }"
      cat.button_category = true
      res = cat.save
      button_category_objects << cat
      puts "ButtonCategory #{ cat.name } created" if res == true
      raise "ERROR: #{ cat.errors.messages }" if res == false
    end
    
    item_objects = []
    category_objects.size.times do |i|
      10.times do |j|
        item = Item.new
        item.company = company
        item.vendor = vendor
        item.tax_profile = tax_profile_objects[j]
        item.category = category_objects[i]
        item.sku = "SKU#{ c }#{ v }#{ i }#{ j }"
        item.name = "Item#{ c }#{ v }#{ i }#{ j }"
        item.item_type = item_type_objects[0]
        res = item.save
        item_objects << item
        puts "Item #{ item.sku } created" if res == true
        raise "ERROR: #{ item.errors.messages }" if res == false
      end
    end
    
    location_objects = []
    3.times do |i|
      l = Location.new
      l.vendor = vendor
      l.company = company
      l.name = "Location#{ c }#{ v }#{ i }"
      res = l.save
      location_objects << l
      puts "#{ l.name } created" if res == true
      raise "ERROR: #{ l.errors.messages }" if res == false
    end
    
    stock_location_objects = []
    3.times do |i|
      l = StockLocation.new
      l.vendor = vendor
      l.company = company
      l.name = "StockLocation#{ c }#{ v }#{ i }"
      res = l.save
      stock_location_objects << l
      puts "#{ l.name } created" if res == true
      raise "ERROR: #{ l.errors.messages }" if res == false
    end
    
    broken_item_objects = []
    3.times do |i|
      b = BrokenItem.new
      b.vendor = vendor
      b.company = company
      b.name = "BrokenItem#{ c }#{ v }#{ i }"
      b.sku = "BI#{ c }#{ v }#{ i }"
      b.quantity = i
      res = b.save
      broken_item_objects << b
      puts "#{ b.name } created" if res == true
      raise "ERROR: #{ b.errors.messages }" if res == false
    end
    
    discount_objects = []
    d = Discount.new
    d.vendor = vendor
    d.company = company
    d.name = "Discount#{ c }#{ v }"
    d.start_date = 1.week.ago
    d.end_date = Time.now + 1.week
    d.applies_to = "Item"
    d.item_sku = item_objects[2].sku
    d.amount = 10
    d.amount_type = 'percent'
    res = d.save
    discount_objects << d
    puts "#{ d.name } created" if res == true
    raise "ERROR: #{ d.errors.messages }" if res == false
    
    
    shipment_type_objects = []
    shipment_types_names.size.times do |i|
      st = ShipmentType.new
      st.vendor = vendor
      st.company = company
      st.name = "#{ shipment_types_names[i] }#{ c }#{ v }"
      res = st.save
      shipment_type_objects << st
      puts "#{ st.name } created" if res == true
      raise "ERROR: #{ st.errors.messages }" if res == false
    end
    
    shipper_objects = []
    3.times do |i|
      s = Shipper.new
      s.vendor = vendor
      s.company = company
      s.name = "Shipper#{ c }#{ v }#{ i }"
      res = s.save
      shipper_objects << s
      puts "#{ s.name } created" if res == true
      raise "ERROR: #{ s.errors.messages }" if res == false
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
      res = lc.save
      puts "#{ lc.sku } created" if res == true
      raise "ERROR: #{ lc.errors.messages }" if res == false
      
      cu.loyalty_cards << lc
      res = cu.save
      customer_objects << cu
      
      puts "#{ cu.first_name } #{ cu.last_name } created" if res == true
      raise "ERROR: #{ cu.errors.messages }" if res == false
    end
    
    transaction_tag_objects = []
    transaction_tag_names.size.times do |i|
      tt = TransactionTag.new
      tt.vendor = vendor
      tt.company = company
      tt.name = "#{ transaction_tag_names[i] }#{ c }#{ v }"
      res = tt.save
      transaction_tag_objects << tt
      puts "#{ tt.name } created" if res == true
      raise "ERROR: #{ tt.errors.messages }" if res == false
    end
    
    country_objects = []
    country_names.size.times do |i|
      co = Country.new
      co.vendor = vendor
      co.company = company
      co.name = "#{ country_names[i] }#{ c }#{ v }"
      res = co.save
      country_objects << co
      puts "#{ co.name } created" if res == true
      raise "ERROR: #{ co.errors.messages }" if res == false
    end
    
    sale_type_objects = []
    sale_type_names.size.times do |i|
      st = SaleType.new
      st.vendor = vendor
      st.company = company
      st.name = "#{ sale_type_names[i] }#{ c }#{ v }"
      res = st.save
      sale_type_objects << st
      puts "#{ st.name } created" if res == true
      raise "ERROR: #{ st.errors.messages }" if res == false
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
        b.save
        button_objects << b
        puts "#{ b.name } created" if res == true
        raise "ERROR: #{ b.errors.messages }" if res == false
      end
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
        res = ib.save
        invoice_blurb_objects << ib
        puts "InvoiceBlurb #{ ib.body } created" if res == true
        raise "ERROR: #{ ib.errors.messages }" if res == false
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
          res = ivn.save
          invoice_note_objects << ivn
          puts "InvoiceNote #{ ivn.name } created" if res == true
          raise "ERROR: #{ ivn.errors.messages }" if res == false
        end
      end
    end
    
    
    
  end
    
    
end
    
    
    
    
      
      
    
    

    
    
    


