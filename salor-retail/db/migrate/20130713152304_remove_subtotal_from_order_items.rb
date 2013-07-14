class RemoveSubtotalFromOrderItems < ActiveRecord::Migration
  def up
    remove_column :order_items, :subtotal_cents
    remove_column :order_items, :subtotal_currency
  end

  def down
  end
end
