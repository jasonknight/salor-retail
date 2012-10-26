class AddThemeToEmployees < ActiveRecord::Migration
  def self.up
    add_column :employees, :theme, :string
  end

  def self.down
    remove_column :employees, :theme
  end
end
