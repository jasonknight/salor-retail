class RemoveTaxValueFromItems < ActiveRecord::Migration
  def self.up
    remove_column :items,:tax_value
  end

  def self.down
  end
end
