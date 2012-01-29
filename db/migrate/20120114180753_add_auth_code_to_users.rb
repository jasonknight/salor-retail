class AddAuthCodeToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :auth_code, :integer
    add_column :employees, :auth_code, :integer
  end

  def self.down
    remove_column :users, :auth_code
    remove_column :employees, :auth_code
  end
end
