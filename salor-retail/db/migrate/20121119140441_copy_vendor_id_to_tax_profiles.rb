class CopyVendorIdToTaxProfiles < ActiveRecord::Migration
  def up
    vendor = Vendor.first
    TaxProfile.update_all :vendor_id => vendor.id if vendor
  end

  def down
  end
end
