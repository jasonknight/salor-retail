class CopyVendorIdOfLoyaltyCards < ActiveRecord::Migration
  def up
    vendor = Vendor.first
    LoyaltyCard.update_all :vendor_id => vendor.id if vendor
  end

  def down
  end
end
