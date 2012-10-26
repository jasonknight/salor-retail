class AddWsFieldsToConfigurations < ActiveRecord::Migration
  def self.up
    add_column :configurations, :csv_imports, :text
    add_column :configurations, :csv_imports_url, :string
  end

  def self.down
    remove_column :configurations, :csv_imports_url
    remove_column :configurations, :csv_imports
  end
end
