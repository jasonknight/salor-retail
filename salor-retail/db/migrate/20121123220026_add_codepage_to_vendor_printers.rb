class AddCodepageToVendorPrinters < ActiveRecord::Migration
  def change
    add_column :vendor_printers, :codepage, :integer
  end
end
