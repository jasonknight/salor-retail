class AddUsernameToEmployees < ActiveRecord::Migration
  def self.up
    add_column :employees, :username, :string
  end

  def self.down
    remove_column :employees, :username
  end
end
