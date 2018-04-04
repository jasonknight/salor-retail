class MoveCalculateTax < ActiveRecord::Migration
  def up
    remove_column :vendors, :calculate_tax
    add_column :salor_configurations, :calculate_tax, :boolean, :default => false
  end

  def down
  end
end
