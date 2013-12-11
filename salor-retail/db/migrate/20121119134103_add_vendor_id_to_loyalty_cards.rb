class AddVendorIdToLoyaltyCards < ActiveRecord::Migration
  def change
    add_column :loyalty_cards, :vendor_id, :integer
  end
end
