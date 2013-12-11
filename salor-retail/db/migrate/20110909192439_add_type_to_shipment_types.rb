class AddTypeToShipmentTypes < ActiveRecord::Migration
  def self.up
    add_column :shippers, :reorder_type, :string
  end

  def self.down
    remove_column :shippers, :reorder_type
  end
end
