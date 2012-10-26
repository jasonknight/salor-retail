class AddDiscountAmountToOrderItems < ActiveRecord::Migration
  def self.up
    add_column :order_items, :discount_amount, :float, :default => 0
    OrderItem.where('discount_applied = 1').all.each do |oi|
      next if oi.item.base_price == oi.price
      damount = oi.item.base_price - oi.price
      oi.update_attribute(:discount_amount,damount)
    end
  end

  def self.down
    remove_column :order_items, :discount_amount
  end
end
