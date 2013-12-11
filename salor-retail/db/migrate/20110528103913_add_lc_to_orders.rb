class AddLcToOrders < ActiveRecord::Migration
  def self.up
    add_column :orders, :lc_points, :integer
  end

  def self.down
    remove_column :orders, :lc_points
  end
end
