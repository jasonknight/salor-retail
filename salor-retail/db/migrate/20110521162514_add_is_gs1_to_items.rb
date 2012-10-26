class AddIsGs1ToItems < ActiveRecord::Migration
  def self.up
    add_column :items, :is_gs1, :boolean, :default => false
  end

  def self.down
    remove_column :items, :is_gs1
  end
end
