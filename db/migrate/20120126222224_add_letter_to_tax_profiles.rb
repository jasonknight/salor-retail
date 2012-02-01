class AddLetterToTaxProfiles < ActiveRecord::Migration
  def self.up
    begin
      add_column :tax_profiles, :letter, :string, :default => 'A'
    rescue
    end
  end

  def self.down
    remove_column :tax_profiles, :letter
  end
end
