class AddCashRegisterIdToVendorPrinter < ActiveRecord::Migration
  def self.up
    add_column :vendor_printers, :cash_register_id, :integer
  end

  def self.down
    remove_column :vendor_printers, :cash_register_id
  end
end
