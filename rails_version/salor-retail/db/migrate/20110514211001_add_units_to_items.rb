class AddUnitsToItems < ActiveRecord::Migration
  def self.up
    add_column :items, :height, :float, :default => 0
    add_column :items, :weight, :float, :default => 0
    add_column :items, :height_metric, :string
    add_column :items, :weight_metric, :string
    add_column :items, :length, :float, :default => 0
    add_column :items, :width, :float, :default => 0
    add_column :items, :length_metric, :string
    add_column :items, :width_metric, :string
  end

  def self.down
    remove_column :items, :width_metric
    remove_column :items, :length_metric
    remove_column :items, :width
    remove_column :items, :length
    remove_column :items, :weight_metric
    remove_column :items, :height_metric
    remove_column :items, :weight
    remove_column :items, :height
  end
end
