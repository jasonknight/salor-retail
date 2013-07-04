class RemoveFieldsFromOrders < ActiveRecord::Migration
  def up
    remove_column :orders, :rebate_type
    rename_column :orders, :lc_discount_amount, :lc_amount
  end

  def down
  end
end
