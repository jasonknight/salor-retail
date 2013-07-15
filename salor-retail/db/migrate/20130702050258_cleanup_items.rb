class CleanupItems < ActiveRecord::Migration
  def up
    remove_column :items, :tax_profile_amount
    remove_column :order_items, :discount_applies
    remove_column :order_items, :coupon_applies
  end

  def down
  end
end
