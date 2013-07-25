class AddToShipmentItems < ActiveRecord::Migration
  def up
    add_column :shipment_items, :total_cents, :integer
    add_column :shipment_items, :purchase_price_total_cents, :integer
  end

  def down
  end
end
