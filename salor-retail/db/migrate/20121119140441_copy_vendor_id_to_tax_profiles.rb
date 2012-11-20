class CopyVendorIdToTaxProfiles < ActiveRecord::Migration
  def up
    TaxProfile.update_all :vendor_id => Vendor.first.id
  end

  def down
  end
end
