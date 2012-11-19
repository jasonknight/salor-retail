class CopyVendorIdOfLoyaltyCards < ActiveRecord::Migration
  def up
    LoyaltyCard.update_all :vendor_id => Vendor.first.id
  end

  def down
  end
end
