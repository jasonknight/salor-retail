class CreateShipmentItems < ActiveRecord::Migration
  def self.up
    create_table :shipment_items do |t|
      t.string :name
      t.float :base_price
      t.integer :category_id
      t.integer :location_id
      t.integer :item_type_id
      t.string :sku
      t.integer :shipment_id

      t.timestamps
    end
  end

  def self.down
    drop_table :shipment_items
  end
end
