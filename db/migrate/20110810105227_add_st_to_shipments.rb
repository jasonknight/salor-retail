class AddStToShipments < ActiveRecord::Migration
  def self.up
    add_column :shipments, :shipment_type_id, :integer
  end

  def self.down
    remove_column :shipments, :shipment_type_id
  end
end
