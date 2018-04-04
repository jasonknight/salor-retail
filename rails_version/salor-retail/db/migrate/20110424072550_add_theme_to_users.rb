class AddThemeToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :theme, :string
  end

  def self.down
    remove_column :users, :theme
  end
end
