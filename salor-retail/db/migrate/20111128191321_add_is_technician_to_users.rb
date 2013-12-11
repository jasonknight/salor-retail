class AddIsTechnicianToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :is_technician, :boolean
  end

  def self.down
    remove_column :users, :is_technician
  end
end
