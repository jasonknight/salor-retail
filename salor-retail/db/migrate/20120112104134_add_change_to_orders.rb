class AddChangeToOrders < ActiveRecord::Migration
  def self.up
    add_column :orders, :front_end_change, :float, :default => 0.0
  end

  def self.down
    remove_column :orders, :front_end_change
  end
end
