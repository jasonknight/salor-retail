class CleanupUnused < ActiveRecord::Migration
  def up
    remove_column :order_items, :refund_payment_method_internal_type
    remove_column :payment_method_items, :internal_type
    add_column :payment_method_items, :order_item_id, :integer
  end

  def down
  end
end
