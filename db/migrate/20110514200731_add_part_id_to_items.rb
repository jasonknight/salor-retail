class AddPartIdToItems < ActiveRecord::Migration
  def self.up
    add_column :items, :part_id, :integer
  end

  def self.down
    remove_column :items, :part_id
  end
end
