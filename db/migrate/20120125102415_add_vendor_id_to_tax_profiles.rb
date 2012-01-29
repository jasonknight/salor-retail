class AddVendorIdToTaxProfiles < ActiveRecord::Migration
  def self.up
    add_column :tax_profiles, :vendor_id, :integer
  end

  def self.down
    remove_column :tax_profiles, :vendor_id
  end
end
