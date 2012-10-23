class AddLogoToVendor < ActiveRecord::Migration
  def self.up
    add_column :vendors, :logo_image_content_type, :string
    add_column :vendors, :logo_image, :binary
  end

  def self.down
    remove_column :vendors, :logo_image
    remove_column :vendors, :logo_image_content_type
  end
end
