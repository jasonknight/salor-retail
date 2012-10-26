class AddLogoToTransactionTags < ActiveRecord::Migration
  def self.up
    add_column :transaction_tags, :logo_image, :binary
    add_column :transaction_tags, :logo_image_content_type, :string
  end

  def self.down
    remove_column :transaction_tags, :logo_image_content_type
    remove_column :transaction_tags, :logo_image
  end
end
