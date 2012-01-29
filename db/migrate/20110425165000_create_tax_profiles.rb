class CreateTaxProfiles < ActiveRecord::Migration
  def self.up
    create_table :tax_profiles do |t|
      t.string :name
      t.float :value
      t.integer :default
      t.integer :vendor_id

      t.timestamps
    end
  end

  def self.down
    drop_table :tax_profiles
  end
end
