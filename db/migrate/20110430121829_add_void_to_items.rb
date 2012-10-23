class AddVoidToItems < ActiveRecord::Migration
  def self.up
    add_column :items, :void, :integer
  end

  def self.down
    remove_column :items, :void
  end
end
