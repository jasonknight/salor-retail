class AddBuyOrderToOrders < ActiveRecord::Migration
  def self.up
    add_column :orders, :buy_order, :boolean, :default => false
  end

  def self.down
    remove_column :orders, :buy_order
  end
end
