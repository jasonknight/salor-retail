class AddFields2ToActions < ActiveRecord::Migration
  def self.up
    add_column :actions, :weight, :integer, :default => 0
    add_column :actions, :afield, :string
    add_column :actions, :value, :float, :default => 0
  end

  def self.down
    remove_column :actions, :weight
    remove_column :actions, :afield
    remove_column :actions, :value
  end
end
