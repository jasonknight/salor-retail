class AddTagToCategories < ActiveRecord::Migration
  def self.up
    add_column :categories, :tag, :string
  end

  def self.down
    remove_column :categories, :tag
  end
end
