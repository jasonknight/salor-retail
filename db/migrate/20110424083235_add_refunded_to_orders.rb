class AddRefundedToOrders < ActiveRecord::Migration
  def self.up
    add_column :orders, :refunded, :boolean, :default => false
  end

  def self.down
    remove_column :orders, :refunded
  end
end
