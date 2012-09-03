class AddItemTypeIdToItems < ActiveRecord::Migration
  def self.up
    add_column :items, :item_type_id, :integer
  end

  def self.down
    remove_column :items, :item_type_id
  end
end
