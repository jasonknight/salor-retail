class AddVendorIdToShipmentTypes < ActiveRecord::Migration
  def change
    add_column :shipment_types, :vendor_id, :integer
  end
end
