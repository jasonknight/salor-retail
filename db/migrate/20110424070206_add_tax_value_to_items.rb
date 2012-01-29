class AddTaxValueToItems < ActiveRecord::Migration
  def self.up
    add_column :items, :tax_value, :float, :default => 0
  end

  def self.down
    remove_column :items, :tax_value
  end
end
