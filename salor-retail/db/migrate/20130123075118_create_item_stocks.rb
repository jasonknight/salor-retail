class CreateItemStocks < ActiveRecord::Migration
  def change
    begin
      create_table :item_stocks do |t|
        t.references :item
        t.references :stock_location
        t.float :quantity
        t.references :location

        t.timestamps
      end
      add_index :item_stocks, :item_id
      add_index :item_stocks, :stock_location_id
      add_index :item_stocks, :location_id
    rescue
      puts $!.inspect
    end
  end
end
