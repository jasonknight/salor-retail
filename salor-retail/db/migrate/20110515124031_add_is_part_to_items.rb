class AddIsPartToItems < ActiveRecord::Migration
  def self.up
    add_column :items, :is_part, :integer
  end

  def self.down
    remove_column :items, :is_part
  end
end
