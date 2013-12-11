class RemoveLogosFromVendorAndTags < ActiveRecord::Migration
  def up
    remove_column :vendors, :logo_image_content_type
    remove_column :vendors, :logo_image
    remove_column :vendors, :logo_invoice_image_content_type
    remove_column :vendors, :logo_invoice_image
    remove_column :transaction_tags, :logo_image_content_type
    remove_column :transaction_tags, :logo_image
  end

  def down
  end
end
