class AddVendorIdToVendorPrinters < ActiveRecord::Migration
  def self.up
    add_column :vendor_printers, :vendor_id, :integer
  end

  def self.down
    remove_column :vendor_printers, :vendor_id
  end
end
