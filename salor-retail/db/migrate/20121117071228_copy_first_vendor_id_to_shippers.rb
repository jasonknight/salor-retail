class CopyFirstVendorIdToShippers < ActiveRecord::Migration
  def up
    Shipper.update_all :vendor_id => Vendor.first.id
  end

  def down
  end
end
