class AddWasPrintedToOrders < ActiveRecord::Migration
  def self.up
    add_column :orders, :was_printed, :boolean
  end

  def self.down
    remove_column :orders, :was_printed
  end
end
