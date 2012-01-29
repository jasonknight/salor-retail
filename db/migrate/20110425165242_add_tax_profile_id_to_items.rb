class AddTaxProfileIdToItems < ActiveRecord::Migration
  def self.up
    add_column :items, :tax_profile_id, :integer
  end

  def self.down
    remove_column :items, :tax_profile_id
  end
end
