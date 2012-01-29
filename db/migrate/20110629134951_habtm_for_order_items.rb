class HabtmForOrderItems < ActiveRecord::Migration
  def self.up
    create_table :discounts_order_items,:id => false do |t|
      t.references :order_item
      t.references :discount
    end
    create_table :discounts_orders,:id => false do |t|
      t.references :order
      t.references :discount
    end
    add_column(:orders,:discount_amount,:float,:default => 0)
  end

  def self.down
    drop_table(:discounts_order_items)
    drop_table(:discounts_orders)
    remove_column(:orders,:discount_amount)
  end
end
