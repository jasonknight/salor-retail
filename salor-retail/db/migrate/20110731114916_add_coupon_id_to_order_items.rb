class AddCouponIdToOrderItems < ActiveRecord::Migration
  def self.up
    add_column :order_items, :coupon_id, :integer, :default => 0
    add_index :order_items, :coupon_id
  end

  def self.down
    remove_column :order_items, :coupon_id
  end
end
