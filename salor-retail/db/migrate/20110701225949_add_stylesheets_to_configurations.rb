class AddStylesheetsToConfigurations < ActiveRecord::Migration
  def self.up
    add_column :configurations, :stylesheets, :string
  end

  def self.down
    remove_column :configurations, :stylesheets
  end
end
