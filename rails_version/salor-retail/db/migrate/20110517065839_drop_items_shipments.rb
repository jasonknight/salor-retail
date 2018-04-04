class DropItemsShipments < ActiveRecord::Migration
  def self.up
    drop_table :items_shipments
  end

  def self.down
  end
end
