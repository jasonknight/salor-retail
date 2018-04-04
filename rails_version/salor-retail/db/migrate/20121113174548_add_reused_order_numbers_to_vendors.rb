class AddReusedOrderNumbersToVendors < ActiveRecord::Migration
  def change
    add_column :vendors, :use_order_numbers, :boolean, :default => true
    add_column :vendors, :unused_order_numbers, :string, :default => "--- []\n"
    add_column :vendors, :largest_order_number, :integer, :default => 0
    add_column :orders, :nr, :integer
  end
end
