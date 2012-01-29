class AddIndexesToShipmentTypes < ActiveRecord::Migration
  def self.up
    add_index :shipment_types, :name
    add_index :shipment_types, :user_id
  end

  def self.down
    remove_index :shipment_types, :name
    remove_index :shipment_types, :user_id
  end
end
