class AddDecPointsToItems < ActiveRecord::Migration
  def self.up
    add_column :items, :decimal_points, :integer
  end

  def self.down
    remove_column :items, :decimal_points
  end
end
