class AddNoIncToOrderItem < ActiveRecord::Migration
  def self.up
    add_column :order_items, :no_inc, :boolean, :default => false
  end

  def self.down
    remove_column :order_items, :no_inc
  end
end
