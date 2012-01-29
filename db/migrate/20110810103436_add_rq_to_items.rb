class AddRqToItems < ActiveRecord::Migration
  def self.up
    add_column :items, :real_quantity, :float, :default => 0.0
  end

  def self.down
    remove_column :items, :real_quantity
  end
end
