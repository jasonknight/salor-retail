class AddUsesDrawerIdToEmployees < ActiveRecord::Migration
  def self.up
    add_column :employees, :uses_drawer_id, :integer
  end

  def self.down
    remove_column :employees, :uses_drawer_id
  end
end
