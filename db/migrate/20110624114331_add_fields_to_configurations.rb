class AddFieldsToConfigurations < ActiveRecord::Migration
  def self.up
    add_column :configurations, :pagination, :integer, :default => 10
  end

  def self.down
    remove_column :configurations, :pagination
  end
end
