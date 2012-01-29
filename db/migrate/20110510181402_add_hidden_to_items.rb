class AddHiddenToItems < ActiveRecord::Migration
  def self.up
    add_column :items, :hidden, :integer, :default => 0
  end

  def self.down
    remove_column :items, :hidden
  end
end
