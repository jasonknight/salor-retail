class AddLastcheckToConfigurations < ActiveRecord::Migration
  def self.up
    add_column :configurations, :last_wholesaler_check, :datetime
  end

  def self.down
    remove_column :configurations, :last_wholesaler_check
  end
end
