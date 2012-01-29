class AddCashMadeToCategories < ActiveRecord::Migration
  def self.up
    add_column :categories, :cash_made, :float
  end

  def self.down
    remove_column :categories, :cash_made
  end
end
