class ItemsShipments < ActiveRecord::Migration
  def self.up
    create_table :items_shipments, :id => false do |t|
      t.references :shipment
      t.references :item
    end
  end

  def self.down
    drop_table :items_shipments
  end
end
