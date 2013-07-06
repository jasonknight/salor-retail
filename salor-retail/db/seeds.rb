# Copyright (c) 2012 Red (E) Tools Ltd.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# if User.any?
#   puts "Database is already seeded. Danger of overwriting database records. Not running seed script again."
#   Process.exit 0
# end


ActiveRecord::Base.connection.tables.each do |t|      
  begin
    model = t.classify.constantize
    model.reset_column_information
  rescue
    next
  end
  puts "Purging table #{ model }"
  model.delete_all
end

company_count = 0

if ENV['SEED_MODE'] == 'full'
  puts "SEED_MODE is 'full'"
  countries = ['us','at','fr','es','pl','hu','ru','it','tr','cn','el','hk','tw']
  languages = ['en','gn','fr','es','pl','hu','ru','it','tr','cn','el','hk','tw']
  company_count = 2
else
  puts "SEED_MODE is 'minimal'"
  countries = ['us', 'at']
  languages = ['en', 'gn']
  company_count = 1
end

tax_percentages = [20, 10, 0]
role_names = [:manager, :head_cashier, :cashier, :stockboy]
payment_method_names = ['Cash', 'Card', 'Other','Change']
item_type_behaviors = ['normal', 'gift_card', 'coupon']
item_type_names = ['Normal Item', 'Gift Card', 'Coupon']

cash_register_names = ['Local', 'Remote']
cash_register_salor_printer = [nil, true]


company_count.times do |c|
  company = Company.new
  company.name = "Company#{ c }"
  company.identifier = c
  r = company.save
  puts "\n\n =========\nCOMPANY #{ c } created\n\n" if r == true
  
  countries.size.times do |v|
    vendor = Vendor.new
    vendor.name = "Vendor#{ c }#{ v }"
    vendor.country = countries[v]
    vendor.company = company
    vendor.hash_id = "vendor#{c}#{v}"
    r = vendor.save
    puts "\n---------\nVENDOR #{ c } #{ v } created\n" if r == true
    
    
    item_type_objects = []
    item_type_behaviors.size.times do |i|
      it = ItemType.new
      it.company = company
      it.vendor = vendor
      it.name = "#{ item_type_names[i] }#{ c } #{ v }"
      it.behavior = item_type_behaviors[i]
      r = it.save
      item_type_objects << it
      puts "ItemType #{ c } #{ v } created" if r == true
    end
    
    cash_register_objects = []
    cash_register_names.size.times do |i|
      cr = CashRegister.new
      cr.name = "#{ cash_register_names[i] }#{ c } #{ v }"
      cr.vendor = vendor
      cr.company = company
      cr.salor_printer = cash_register_salor_printer[i]
      r = cr.save
      cash_register_objects << cr
      puts "CashRegister #{ cr.name } created" if r == true
    end
    
    role_objects = []
    role_names.size.times do |i|
      r = Role.new
      r.company = company
      r.vendor = vendor
      r.name = "#{ role_names[i] }#{ c }#{ v }"
      res = r.save
      role_objects << r
      puts "Role #{ r.name } created" if res == true
    end
    
    user_objects = []
    role_objects.size.times do |i|
      u = User.new
      u.company = company
      u.vendor = vendor
      u.roles = [role_objects[i]]
      u.password = "#{ c }#{ v }#{ i }"
      u.username = "#{ role_names[i] }#{ c }#{ v }"
      u.language = languages[c]
      res = u.save
      user_objects << u
      puts "User #{ u.username } with password #{ c }#{ v }#{ i } created. Drawer is #{ u.drawer_id }" if res == true
      u.save # needs to be called since drawer_id was not persistent after the last save
    end
    
    tax_profile_objects = []
    tax_percentages.size.times do |i|
      tp = TaxProfile.new
      tp.company = company
      tp.vendor = vendor
      tp.name = "#{ tax_percentages[i] }%"
      tp.value = tax_percentages[i]
      res = tp.save
      tax_profile_objects << tp
      puts "TaxProfile #{ tp.name } created" if res == true
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
    end
    3.upto(5) do |i|
      cat = Category.new
      cat.company = company
      cat.vendor = vendor
      cat.name = "ButtonCategory#{ c }#{ v }#{ i }"
      cat.button_category = true
      res = cat.save
      category_objects << cat
      puts "ButtonCategory #{ cat.name } created" if res == true
    end
    
    item_objects = []
    category_objects.size.times do |i|
      3.times do |j|
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
      end
    end
  end
end
    
    
    
    
      
      
    
    

    
    
    


