class AddCopiesToVendorPrinters < ActiveRecord::Migration
  def change
    add_column :vendor_printers, :copies, :integer, :default => 1
  end
end
