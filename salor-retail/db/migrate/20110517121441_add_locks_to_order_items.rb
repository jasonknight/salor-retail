class AddLocksToOrderItems < ActiveRecord::Migration
  def self.up
    add_column :order_items, :total_is_locked, :boolean, :default => false
    add_column :order_items, :tax_is_locked, :boolean, :default => false
  end

  def self.down
    remove_column :order_items, :tax_is_locked
    remove_column :order_items, :total_is_locked
  end
end
