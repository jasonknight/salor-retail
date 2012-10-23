class AddVendorIdToShipments < ActiveRecord::Migration
  def self.up
    add_column :shipments, :vendor_id, :integer
  end

  def self.down
    remove_column :shipments, :vendor_id
  end
end
