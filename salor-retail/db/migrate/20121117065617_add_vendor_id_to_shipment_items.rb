class AddVendorIdToShipmentItems < ActiveRecord::Migration
  def change
    add_column :shipment_items, :vendor_id, :integer
  end
end
