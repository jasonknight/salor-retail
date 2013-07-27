class TransformItemStocks4 < ActiveRecord::Migration
  def up
    change_column_default :item_stocks, :quantity, 0
    Vendor.connection.execute("UPDATE item_stocks SET quantity = 0 WHERE quantity IS NULL")
  end

  def down
  end
end
