class AddIsShipmentItemToBrokenItems < ActiveRecord::Migration
  def self.up
    add_column :broken_items, :is_shipment_item, :boolean, :default => false
  end

  def self.down
    remove_column :broken_items, :is_shipment_item
  end
end
