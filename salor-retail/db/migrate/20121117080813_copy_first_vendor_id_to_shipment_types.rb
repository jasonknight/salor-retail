class CopyFirstVendorIdToShipmentTypes < ActiveRecord::Migration
  def up
    ShipmentType.update_all :vendor_id =>  Vendor.first.id
  end

  def down
  end
end
