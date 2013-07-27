class TransformItemStocks1 < ActiveRecord::Migration
  def up
    add_column :item_stocks, :location_type, :string
  end

  def down
  end
end
