class RemoveFromVendors < ActiveRecord::Migration
  def up
    remove_column :vendors, :calculate_tax
  end

  def down
  end
end
