class AddRebateToOrders < ActiveRecord::Migration
  def self.up
    add_column :orders, :rebate, :float, :default => 0
    add_column :orders, :rebate_type, :string
  end

  def self.down
    remove_column :orders, :rebate_type
    remove_column :orders, :rebate
  end
end
