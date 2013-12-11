class AddCouponAmountToOrderItems < ActiveRecord::Migration
  def self.up
    add_column :order_items, :coupon_amount, :float, :default => 0
  end

  def self.down
    remove_column :order_items, :coupon_amount
  end
end
