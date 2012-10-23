class AddRefunded < ActiveRecord::Migration
  def self.up
    add_column :order_items, :refunded, :boolean, :default => false
  end

  def self.down
     remove_column :order_items, :refunded, :boolean, :default => false
  end
end
