class AddMultiCurrencyToVendors < ActiveRecord::Migration
  def self.up
    add_column :vendors, :multi_currency, :boolean, :default => false
  end

  def self.down
    remove_column :vendors, :multi_currency
  end
end
