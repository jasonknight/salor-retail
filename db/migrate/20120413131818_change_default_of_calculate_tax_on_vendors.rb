class ChangeDefaultOfCalculateTaxOnVendors < ActiveRecord::Migration
  def up
    change_column_default :vendors, :calculate_tax, false
  end

  def down
  end
end
