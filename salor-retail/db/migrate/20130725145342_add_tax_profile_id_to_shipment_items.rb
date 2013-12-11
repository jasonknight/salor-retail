class AddTaxProfileIdToShipmentItems < ActiveRecord::Migration
  def change
    add_column :shipment_items, :tax_profile_id, :integer
  end
end
