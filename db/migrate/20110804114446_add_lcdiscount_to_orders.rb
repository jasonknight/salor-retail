class AddLcdiscountToOrders < ActiveRecord::Migration
  def self.up
    add_column :orders, :lc_discount_amount, :float, :default => 0.0
  end

  def self.down
    remove_column :orders, :lc_discount_amount
  end
end
