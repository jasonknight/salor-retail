class AddCategoryIdToItems < ActiveRecord::Migration
  def self.up
    add_column :items, :category_id, :integer
  end

  def self.down
    remove_column :items, :category_id
  end
end
