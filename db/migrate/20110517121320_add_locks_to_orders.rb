class AddLocksToOrders < ActiveRecord::Migration
  def self.up
    add_column :orders, :total_is_locked, :boolean, :default => false
    add_column :orders, :tax_is_locked, :boolean, :default => false
    add_column :orders, :subtotal_is_locked, :boolean, :default => false
  end

  def self.down
    remove_column :orders, :subtotal_is_locked
    remove_column :orders, :tax_is_locked
    remove_column :orders, :total_is_locked
  end
end
