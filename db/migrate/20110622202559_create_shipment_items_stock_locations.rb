class CreateShipmentItemsStockLocations < ActiveRecord::Migration
  def self.up
    create_table(:shipment_items_stock_locations,:id => false) do |t|
      t.references :shipment_item
      t.references :stock_location
    end
  end

  def self.down
    drop_table(:shipment_items_stock_locations)
  end
end
