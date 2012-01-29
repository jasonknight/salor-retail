class AddApitokenToEmployees < ActiveRecord::Migration
  def self.up
    add_column :employees, :apitoken, :string
  end

  def self.down
    remove_column :employees, :apitoken
  end
end
