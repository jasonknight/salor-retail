class Feature468 < ActiveRecord::Migration
  def self.up
    add_column :items, :shipper_id, :integer
    add_column :items, :shipper_sku, :string
    add_column :items, :packaging_unit,:float, :default => 1.0
  end

  def self.down
    remove_column :items, :shipper_id
    remove_column :items, :shipper_sku
    remove_column :items, :packaging_unit
  end
end
