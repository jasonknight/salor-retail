class AddInStockQuantityToShipmentItems < ActiveRecord::Migration
  def change
    add_column :shipment_items, :in_stock_quantity, :float
  end
end
