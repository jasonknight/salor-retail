class AddHiddenToShipmentItems < ActiveRecord::Migration
  def change
    add_column :shipment_items, :hidden, :boolean
    add_column :shipment_items, :hidden_by, :integer
  end
end
