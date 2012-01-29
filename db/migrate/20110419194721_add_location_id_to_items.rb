class AddLocationIdToItems < ActiveRecord::Migration
  def self.up
    add_column :items, :location_id, :integer
  end

  def self.down
    remove_column :items, :location_id
  end
end
