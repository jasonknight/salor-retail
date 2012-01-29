class AddHiddenToOrders < ActiveRecord::Migration
  def self.up
    add_column :orders, :hidden, :integer, :default => 0
  end

  def self.down
    remove_column :orders, :hidden
  end
end
