class AddHiddenToStockLocations < ActiveRecord::Migration
  def change
    add_column :stock_locations, :hidden, :boolean
    add_column :stock_locations, :hidden_by, :integer
  end
end
