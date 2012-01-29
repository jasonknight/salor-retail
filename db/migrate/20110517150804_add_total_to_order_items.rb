class AddTotalToOrderItems < ActiveRecord::Migration
  def self.up
    add_column :order_items, :total, :float, :default => 0
  end

  def self.down
    remove_column :order_items, :total
  end
end
