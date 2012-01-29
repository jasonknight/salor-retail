class AddRebateToOrderItems < ActiveRecord::Migration
  def self.up
    add_column :order_items, :rebate, :float
  end

  def self.down
    remove_column :order_items, :rebate
  end
end
