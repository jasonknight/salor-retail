class AddLogoInvoiceToVendor < ActiveRecord::Migration
  def self.up
    add_column :vendors, :logo_invoice_image, :binary
    add_column :vendors, :logo_invoice_image_content_type, :binary
  end

  def self.down
    remove_column :vendors, :logo_invoice_image
    remove_column :vendors, :logo_invoice_image_content_type
  end
end
