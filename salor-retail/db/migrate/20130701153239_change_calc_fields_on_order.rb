class ChangeCalcFieldsOnOrder < ActiveRecord::Migration
  def change
    rename_column :orders, :tax, :tax_amount
    add_column :orders, :tax, :float
    add_column :orders, :tax_profile_id, :integer
    add_column :orders, :rebate_amount, :float
  end
end
