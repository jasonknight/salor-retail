class AddCashDrawerFieldsToConfigurations < ActiveRecord::Migration
  def self.up
    add_column :configurations, :cash_drawer, :string
    add_column :configurations, :open_cash_drawer, :boolean, :default => false
  end

  def self.down
    remove_column :configurations, :open_cash_drawer
    remove_column :configurations, :cash_drawer
  end
end
