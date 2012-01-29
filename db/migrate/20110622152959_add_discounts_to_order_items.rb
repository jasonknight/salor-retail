class AddDiscountsToOrderItems < ActiveRecord::Migration
  def self.up
    add_column :order_items, :discount_applied, :boolean, :default => false
    add_column :order_items, :coupon_applied, :boolean, :default => false
  end

  def self.down
    remove_column :order_items, :coupond_applied
    remove_column :order_items, :discount_applied
  end
end
