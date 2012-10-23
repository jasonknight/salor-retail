class AddCashToOrders < ActiveRecord::Migration
  def self.up
    add_column :orders, :in_cash, :float, :default => 0
    add_column :orders, :by_card, :float, :default => 0
  end

  def self.down
    remove_column :orders, :by_card
    remove_column :orders, :in_cash
  end
end
