class AddStatusToNodes < ActiveRecord::Migration
  def self.up
    add_column :nodes, :status, :string
  end

  def self.down
    remove_column :nodes, :status
  end
end
