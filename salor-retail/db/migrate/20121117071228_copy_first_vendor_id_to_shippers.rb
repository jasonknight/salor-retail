class CopyFirstVendorIdToShippers < ActiveRecord::Migration
  def up
    vendor = Vendor.first
    Shipper.update_all :vendor_id => vendor.id if vendor
  end

  def down
  end
end
