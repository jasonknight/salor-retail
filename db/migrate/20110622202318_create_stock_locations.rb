class CreateStockLocations < ActiveRecord::Migration
  def self.up
    create_table :stock_locations do |t|
      t.string :name
      t.references :vendor
      t.timestamps
    end
  end

  def self.down
    drop_table :stock_locations
  end
end
