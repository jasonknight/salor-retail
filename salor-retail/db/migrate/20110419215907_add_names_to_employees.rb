class AddNamesToEmployees < ActiveRecord::Migration
  def self.up
    add_column :employees, :first_name, :string
    add_column :employees, :last_name, :string
  end

  def self.down
    remove_column :employees, :last_name
    remove_column :employees, :first_name
  end
end
