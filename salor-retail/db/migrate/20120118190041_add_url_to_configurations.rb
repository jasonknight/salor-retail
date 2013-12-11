class AddUrlToConfigurations < ActiveRecord::Migration
  def self.up
    add_column :configurations, :url, :string, :default => "http://salor"
  end

  def self.down
    remove_column :configurations, :url
  end
end
