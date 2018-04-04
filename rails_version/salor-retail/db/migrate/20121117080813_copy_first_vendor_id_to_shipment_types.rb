class CopyFirstVendorIdToShipmentTypes < ActiveRecord::Migration
  def up
    vendor = Vendor.first
    ShipmentType.update_all :vendor_id =>  vendor.id if vendor
  end

  def down
  end
end
