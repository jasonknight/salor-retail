class AddFieldsToActions < ActiveRecord::Migration
  def self.up
    add_column :actions, :owner_id, :integer
    add_column :actions, :owner_type, :string
    add_column :actions, :behavior, :string
  end

  def self.down
    remove_column :actions, :behavior
    remove_column :actions, :owner_type
    remove_column :actions, :owner_id
  end
end
