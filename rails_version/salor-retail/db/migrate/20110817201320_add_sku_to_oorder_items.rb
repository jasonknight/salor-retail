class AddSkuToOorderItems < ActiveRecord::Migration
  def self.up
    add_column :order_items, :sku, :string
  end

  def self.down
    remove_column :order_items, :sku
  end
end
