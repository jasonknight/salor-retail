class AddUserIdToTaxProfiles < ActiveRecord::Migration
  def self.up
    add_column :tax_profiles, :user_id, :integer
  end

  def self.down
    remove_column :tax_profiles, :user_id
  end
end
