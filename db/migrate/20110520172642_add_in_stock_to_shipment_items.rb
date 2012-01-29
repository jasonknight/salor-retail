class AddInStockToShipmentItems < ActiveRecord::Migration
  def self.up
    add_column :shipment_items, :in_stock, :boolean, :default => false
  end

  def self.down
    remove_column :shipment_items, :in_stock
  end
end
