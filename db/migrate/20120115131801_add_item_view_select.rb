class AddItemViewSelect < ActiveRecord::Migration
  def self.up
    add_column :configurations, :items_view_list, :boolean, :default => true
  end

  def self.down
    remove_column :configurations, :items_view_list
  end
end
