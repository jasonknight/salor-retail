class AddNameToShipments < ActiveRecord::Migration
  def self.up
    add_column :shipments, :name, :string
  end

  def self.down
    remove_column :shipments, :name
  end
end
