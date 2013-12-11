class AddSlToItemStocks < ActiveRecord::Migration
  def change
    add_column :item_stocks, :stock_location_quantity, :float
    add_column :item_stocks, :location_quantity, :float
  end
end
