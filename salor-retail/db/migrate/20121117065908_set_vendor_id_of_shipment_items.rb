class SetVendorIdOfShipmentItems < ActiveRecord::Migration
  def up
    ShipmentItem.update_all :vendor_id => Vendor.first.id
  end

  def down
  end
end
