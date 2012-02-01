class AddPurchasePriceToShipmentItems < ActiveRecord::Migration
  def change
    add_column :shipment_items, :purchase_price, :float

  end
end
