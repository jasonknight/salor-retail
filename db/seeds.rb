# Consider this file also a tutorial on how the system works
I18n.locale = 'en-US'
ItemType.delete_all
ItemType.new({:name => "Normal Item", :behavior => "normal"}).save!
ItemType.new({:name => "Gift Card", :behavior => "gift_card"}).save!
ItemType.new({:name => "Coupon", :behavior => "coupon"}).save!

# Adding in default roles
Role.delete_all
[ :manager, :head_cashier, :cashier, :stockboy,:edit_others_orders].each do |r|
  role = Role.new(:name => r.to_s)
  role.save
end
[ :orders,:items,:categories, 
  :locations,:shippers,:shipments, 
  :vendors, :employees, :discounts,:tax_profiles,:customers,
  :transaction_tags, :buttons, :stock_locations,:actions,:shipment_items].each do |r|
  [:index,:edit,:destroy,:create,:update,:show].each do |a|
    role = Role.new(:name => a.to_s + '_' + r.to_s)
    role.save
  end
  role = Role.new(:name => 'any_' + r.to_s)
  role.save
end

#add in testing accounts
User.delete_all
@user = User.new(
  {
    :username => 'admin',
    :password => '31202003285',
    :language => 'en-US',
    :email => 'admin@salor.com',
  }
)
if not @user.save then
  puts @user.errors.inspect
end
@vendor = @user.add_vendor("TestVendor")
@tp = TaxProfile.new(:name => "Default",:sku => "DEFAUTLTaxProfile", :value => 7, :user_id => @user.id)
@tp.save
@begin_day_tag = TransactionTag.new(:name => "beginning_of_day", :vendor_id => @vendor.id)
@begin_day_tag.save
@end_day_tag = TransactionTag.new(:name => "end_of_day", :vendor_id => @vendor.id)
#Add in some cash registers

registers = []
CashRegister.delete_all
2.times do |i|
  r = CashRegister.new(
    {
      :name => "Register ##{i+1}",
      :vendor_id => @vendor.id
    }  
  )
  r.save()
  registers << r
end
Employee.delete_all
@cashier = Employee.new(
  {
    :username => 'cashier',
    :password => '31202293395',
    :language => 'en-US',
    :email => 'cashier@salor.com',
    :first_name => "Cashier",
    :last_name => "McCashy",
    :user_id => @user.id,
    :vendor_id => @vendor.id,
    :role_ids => [Role.find_by_name(:cashier).id],
  }
)
@cashier.save()
@head_cashier = Employee.new(
  {
    :username => 'head_cashier',
    :password => '31202153335',
    :language => 'en-US',
    :email => 'head_cashier@salor.com',
    :first_name => "Hedy",
    :last_name => "McCashy",
    :user_id => @user.id,
    :vendor_id => @vendor.id,
    :role_ids => [Role.find_by_name(:head_cashier).id],
  }
)
@head_cashier.save()
@manager = Employee.new(
  {
    :username => 'manager',
    :password => '31202053295',
    :language => 'en-US',
    :email => 'Manager@salor.com',
    :first_name => "Mangy",
    :last_name => "McManager",
    :user_id => @user.id,
    :vendor_id => @vendor.id,
    :role_ids => [Role.find_by_name(:manager).id],
  }
)
@manager.save()
@stockboy = Employee.new(
  {
    :username => 'stockboy',
    :password => '31202323405',
    :language => 'en-US',
    :email => 'stockboy@salor.com',
    :first_name => "Stockborough",
    :last_name => "Stockington the III, Jr., Esq.",
    :user_id => @user.id,
    :vendor_id => @vendor.id,
    :role_ids => [Role.find_by_name(:stockboy).id],
  }
)
@stockboy .save()


