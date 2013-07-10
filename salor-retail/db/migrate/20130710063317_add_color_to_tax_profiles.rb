class AddColorToTaxProfiles < ActiveRecord::Migration
  def change
    add_column :tax_profiles, :color, :string
  end
end
