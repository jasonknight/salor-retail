class AddFieldsToNodesAndChangeSkus < ActiveRecord::Migration
  def change
    add_column :nodes, :accepts_tax_profiles, :boolean, :default => true
    add_column :nodes, :accepts_buttons, :boolean, :default => true
    add_column :nodes, :accepts_categories, :boolean, :default => true
    add_column :nodes, :accepts_items, :boolean, :default => true
    add_column :nodes, :accepts_customers, :boolean, :default => true
    add_column :nodes, :accepts_loyalty_cards, :boolean, :default => true
    add_column :nodes, :accepts_discounts, :boolean, :default => true
    Category.all.each do |cat|
      cat.set_sku
      cat.save
    end
    TaxProfile.all.each do |tp|
      tp.set_sku
      tp.save
    end
  end
end
