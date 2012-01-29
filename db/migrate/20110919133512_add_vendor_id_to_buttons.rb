class AddVendorIdToButtons < ActiveRecord::Migration
  def self.up
    add_column :buttons, :vendor_id, :integer
  end

  def self.down
    remove_column :buttons, :vendor_id
  end
end
