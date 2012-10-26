class AddAutoDropToConfigurations < ActiveRecord::Migration
  def self.up
    add_column :configurations, :auto_drop, :boolean, :default => false
  end

  def self.down
    remove_column :configurations, :auto_drop
  end
end
