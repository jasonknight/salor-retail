class AddUsersVendors < ActiveRecord::Migration
  def change
    create_table "users_vendors", :id => false, :force => true do |t|
      t.integer "user_id"
      t.integer "vendor_id"
    end
  end
  User.all.each do |u|
    u.vendors = Vendor.all
  end
end
