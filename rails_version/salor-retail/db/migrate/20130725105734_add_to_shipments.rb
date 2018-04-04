class AddToShipments < ActiveRecord::Migration
  def up
    add_column :shipments, :total_cents, :integer
    add_column :shipments, :purchase_price_total_cents, :integer
  end

  def down
  end
end
