puts "Salor Test Suite Running, Setting up data"
@vendor = Vendor.first
GlobalData.vendor = @vendor
GlobalData.session = {:vendor_id => @vendor.id}
GlobalData.params = {:no_inc => nil}
@tp = TaxProfile.first
@cashier = Employee.find_by_username('cashier')
$User = @cashier
GlobalData.user_id = @cashier.user.id
@register = CashRegister.where("vendor_id = ?",@vendor.id).first
$Register = @register
@cashier.drawer = Drawer.new(:amount => 500)
@cashier.drawer.save
if not @cashier.meta then
  @cashier.meta = Meta.new
  @cashier.meta.save
end
@cashier.meta.vendor_id = @vendor.id
@cashier.meta.cash_register_id = @register.id
GlobalData.salor_user = @cashier
# create some test categories
puts "Adding in categories"
Category.delete_all
cats = []
5.times do |i|
  c = Category.new(
    {
      :name => "Category #{i + 1}",
      :vendor_id => @vendor.id
    }  
  )
  c.save()
  cats << c
end
puts "Adding in Locations"
Location.delete_all
locs = []
15.times do |i|
  l = Location.new(
    {
      :name => "Aisle #{i + 1}",
      :vendor_id => @vendor.id
    }  
  )
  l.save()
  locs << l
end
puts "Creating 10 test items"
Item.delete_all
items = []
coupons = []
10.times do |i|
  it = Item.new(
    {
      :name => "Test Item #{i+1}",
      :description => "This is the description for Test Item #{i+1}",
      :sku => "I00" + (i+1).to_s,
      :base_price => rand(10) * 10.5 + 0.50,
      :vendor_id => @vendor.id,
      :tax_profile_id => @tp.id,
      :location_id => locs[rand(locs.length)].id,
      :quantity => rand(20),
      :category_id => cats[rand(cats.length)].id,
      :item_type_id => ItemType.find_by_behavior(:normal).id
    }  
  )
  
  if not it.save(:validate => false) then
    puts "Item:" + it.errors.inspect
  end
  co = Item.new(
    {
      :name => "Test Coupon #{i+1}",
      :description => "This is the description for Test Coupon #{i+1}",
      :sku => 'C' + (i+1).to_s,
      :base_price => rand,
      :vendor_id => @vendor.id,
      :tax_profile_id => @tp.id,
      :location_id => locs[rand(locs.length)].id,
      :quantity => rand(40),
      :category_id => cats[rand(cats.length)].id,
      :item_type_id => ItemType.find_by_behavior(:coupon).id,
      :coupon_type => Item::COUPON_TYPES[rand(3)][:value],
      :coupon_applies => it.sku
    }  
  )
  if not co.save(:validate => false) then
    puts co.errors.inspect
  end
  coupons << co
  
  items << it
end

# create some customers
puts "Creating 5 Customers"
lcs = []
Customer.delete_all
5.times do |i|
  c = Customer.new(
    {
      :first_name => "Customer #{i+1}",
      :last_name => "Jones",
      :loyalty_card => LoyaltyCard.new({
        :points => rand(900) + 25,
        :sku => "LC#{i+1}" 
      }),
      :vendor_id => GlobalData.vendor.id
    }
  )
  c.save
  lcs << c
end

# Discount testing
puts "Creating Discounts"
Discount.delete_all

d = Discount.new(
    :name => "Store Percent",
    :start_date => Time.now,
    :end_date => Time.now + 10.days,
    :vendor_id => @vendor.id,
    :applies_to => Discount::APPLIES[0][1],
    :amount => 2,
    :amount_type => Discount::TYPES[0][:value]
  )
#d.save

d = Discount.new(
    :name => "Store Fixed Amount",
    :start_date => Time.now,
    :end_date => Time.now + 10.days,
    :vendor_id => @vendor.id,
    :applies_to => Discount::APPLIES[0][1],
    :amount => 3,
    :amount_type => Discount::TYPES[1][:value]
  )
#d.save

discounted_items = items[0..3]
discounted_items.each do |di|
  d = Discount.new(
    :name => "Item Percent Off for #{di.name}",
    :start_date => Time.now,
    :end_date => Time.now + 10.days,
    :vendor_id => @vendor.id,
    :applies_to => Discount::APPLIES[3][1],
    :amount => 2,
    :amount_type => Discount::TYPES[0][:value],
    :item_sku => di.sku
  )
  #d.save
end
discounted_items = items[4..9]
discounted_items.each do |di|
  d = Discount.new(
    :name => "Item Fixed Off for #{di.sku}",
    :start_date => Time.now,
    :end_date => Time.now + 10.days,
    :vendor_id => @vendor.id,
    :applies_to => Discount::APPLIES[3][1],
    :amount => (di.base_price / 2).round(2),
    :amount_type => Discount::TYPES[1][:value],
    :item_sku => di.sku
  )
  #d.save
end

# Location Discounts
discount_locs = locs[0..2]
discount_locs.each do |dl|
  d = Discount.new(
    :name => "Location Percent Off for #{dl.name}",
    :start_date => Time.now,
    :end_date => Time.now + 10.days,
    :vendor_id => @vendor.id,
    :applies_to => Discount::APPLIES[1][1],
    :amount => 2,
    :amount_type => Discount::TYPES[0][:value]
  )
  #d.save
end

# Category Discounts
discount_cats = locs[0..2]
discount_cats.each do |dc|
  d = Discount.new(
    :name => "Category Percent Off for #{dc.name}",
    :start_date => Time.now,
    :end_date => Time.now + 10.days,
    :vendor_id => @vendor.id,
    :applies_to => Discount::APPLIES[1][1],
    :amount => 2,
    :amount_type => Discount::TYPES[0][:value]
  )
  #d.save
end


# Order Testing
puts "Creating 5 orders"
Order.delete_all
5.times do |i|
  order = @cashier.get_new_order
  4.times do |j|
    item = items[rand(items.length)]
    order.add_item(item)
    coupon = Item.find_by_coupon_applies(item.sku)
    order.add_item(coupon)
    order.update_self_and_save
  end
  gcard = Item.new(
    {
      :name => "Test Gift Card #{i+1}",
      :description => "This is the description for Test Gift Card #{i+1}",
      :sku => 'G' + (i+1).to_s,
      :base_price => 100,
      :vendor_id => @vendor.id,
      :tax_profile_id => @tp.id,
      :location_id => locs[rand(14)].id,
      :quantity => rand(20),
      :category_id => cats[rand(cats.length)].id,
      :item_type_id => ItemType.find_by_behavior(:gift_card).id
    }  
  )
  gcard.save
  oi = order.add_item(gcard)
  order.update_self_and_save
  order.activate_gift_card(oi.id,rand(10))
  order.update_self_and_save
  order.complete
  
  puts "Order ##{order.id} total: #{order.total}"
end
