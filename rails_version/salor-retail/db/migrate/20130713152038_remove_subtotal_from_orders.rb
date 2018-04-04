class RemoveSubtotalFromOrders < ActiveRecord::Migration
  def up
    remove_column :orders, :subtotal_cents
    remove_column :orders, :subtotal_currency
  end

  def down
  end
end
