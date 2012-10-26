class AddReceiptLogosToVendor < ActiveRecord::Migration
  def self.up
    add_column :vendors, :receipt_logo_header, :text
    add_column :vendors, :receipt_logo_footer, :text
  end

  def self.down
    remove_column :vendors, :receipt_logo_footer
    remove_column :vendors, :receipt_logo_header
  end
end
