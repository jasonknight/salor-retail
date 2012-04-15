class AddHiddenFields2 < ActiveRecord::Migration
  def up
    add_column :actions, :hidden, :integer, :default => 0
    add_column :broken_items, :hidden, :integer, :default => 0
    add_column :buttons, :hidden, :integer, :default => 0
    add_column :categories, :hidden, :integer, :default => 0
    add_column :customers, :hidden, :integer, :default => 0
    add_column :drawers, :hidden, :integer, :default => 0
    add_column :locations, :hidden, :integer, :default => 0
    add_column :loyalty_cards, :hidden, :integer, :default => 0
    add_column :nodes, :hidden, :integer, :default => 0
    add_column :shipment_types, :hidden, :integer, :default => 0
    add_column :tender_methods, :hidden, :integer, :default => 0
  end

  def down
  end
end
