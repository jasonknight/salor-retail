class TransformItemStocks3 < ActiveRecord::Migration
  def up
    remove_column :item_stocks, :stock_location_quantity
    remove_column :item_stocks, :stock_location_id
    remove_column :item_stocks, :location_quantity
  end

  def down
  end
end
