class AddItemIdToItem < ActiveRecord::Migration
  def self.up
    add_column :items, :child_id, :integer
  end

  def self.down
    remove_column :items, :child_id
  end
end
