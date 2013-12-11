class SetVendorIdOfShipmentItems < ActiveRecord::Migration
  def up
    vendor = Vendor.first
    ShipmentItem.update_all :vendor_id => vendor.id if vendor
  end

  def down
  end
end
