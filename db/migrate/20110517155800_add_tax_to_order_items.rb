class AddTaxToOrderItems < ActiveRecord::Migration
  def self.up
    add_column :order_items, :tax, :float, :default => 0
  end

  def self.down
    remove_column :order_items, :tax
  end
end
