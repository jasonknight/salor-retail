class AddIggyToItems < ActiveRecord::Migration
  def self.up
    add_column :items, :ignore_qty, :boolean, :default => false
  end

  def self.down
    remove_column :items, :ignore_qty
  end
end
