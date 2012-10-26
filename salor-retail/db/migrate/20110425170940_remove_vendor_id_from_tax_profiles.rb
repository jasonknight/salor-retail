class RemoveVendorIdFromTaxProfiles < ActiveRecord::Migration
  def self.up
    remove_column :tax_profiles, :vendor_id
  end

  def self.down
  end
end
