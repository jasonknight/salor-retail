class AddItemTypeIdAndActivatedToOrderItems < ActiveRecord::Migration
  def self.up
    add_column :order_items, :item_type_id, :integer
    add_column :order_items, :activated, :boolean, :default => 0
  end

  def self.down
    remove_column :order_items, :activated
    remove_column :order_items, :item_type_id
  end
end
