class AddAppliesToLocations < ActiveRecord::Migration
  def self.up
    add_column :locations, :applies_to, :string
  end

  def self.down
    remove_column :locations, :applies_to
  end
end
