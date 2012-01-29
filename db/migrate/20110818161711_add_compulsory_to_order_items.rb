class AddCompulsoryToOrderItems < ActiveRecord::Migration
  def self.up
    add_column :order_items, :weigh_compulsory, :boolean, :default => false
    add_column :items, :weigh_compulsory, :boolean, :default => false
  end

  def self.down
    remove_column :order_items, :weigh_compulsory
    remove_column :items, :weigh_compulsory
  end
end
