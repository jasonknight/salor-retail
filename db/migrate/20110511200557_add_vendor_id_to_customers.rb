class AddVendorIdToCustomers < ActiveRecord::Migration
  def self.up
    add_column :customers, :vendor_id, :integer
  end

  def self.down
    remove_column :customers, :vendor_id
  end
end
