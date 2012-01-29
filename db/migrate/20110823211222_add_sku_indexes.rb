class AddSkuIndexes < ActiveRecord::Migration
  def self.up
    add_index :order_items, :sku
    add_index :order_items, :behavior
    add_index :items, :sku
    add_index :items, :coupon_applies
    add_index :discounts, :applies_to
    add_index :discounts, :amount_type
    add_index :loyalty_cards, :sku
    add_index :payment_methods, :order_id
  end

  def self.down
    remove_index :order_items, :sku
    remove_index :order_items, :behavior
    remove_index :items, :sku
    remove_index :items, :coupon_applies
    remove_index :discounts, :applies_to
    remove_index :discounts, :amount_type
    remove_index :loyalty_cards, :sku
    remove_index :payment_methods, :order_id
  end
end
