class AddVendorIdToOrders < ActiveRecord::Migration
  def self.up
    add_column :orders, :vendor_id, :integer
  end

  def self.down
    remove_column :orders, :vendor_id
  end
end
