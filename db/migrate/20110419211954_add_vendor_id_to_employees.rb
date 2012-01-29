class AddVendorIdToEmployees < ActiveRecord::Migration
  def self.up
    add_column :employees, :vendor_id, :integer
  end

  def self.down
    remove_column :employees, :vendor_id
  end
end
