class AddPrinterTypeToVendorPrinters < ActiveRecord::Migration
  def self.up
    add_column :vendor_printers, :printer_type, :string
  end

  def self.down
    remove_column :vendor_printers, :printer_type
  end
end
