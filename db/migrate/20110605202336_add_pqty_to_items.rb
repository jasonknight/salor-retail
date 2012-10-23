class AddPqtyToItems < ActiveRecord::Migration
  def self.up
    add_column :items, :part_quantity, :float, :default => 0
  end

  def self.down
    remove_column :items, :part_quantity
  end
end
