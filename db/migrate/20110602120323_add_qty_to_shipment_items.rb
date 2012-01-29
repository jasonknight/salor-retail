class AddQtyToShipmentItems < ActiveRecord::Migration
  def self.up
    add_column :shipment_items, :quantity, :float
  end

  def self.down
    remove_column :shipment_items, :quantity
  end
end
