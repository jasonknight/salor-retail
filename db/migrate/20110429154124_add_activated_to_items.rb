class AddActivatedToItems < ActiveRecord::Migration
  def self.up
    add_column :items, :activated, :boolean, :default => false
  end

  def self.down
    remove_column :items, :activated
  end
end
