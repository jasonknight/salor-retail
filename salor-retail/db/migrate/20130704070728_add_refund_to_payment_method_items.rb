class AddRefundToPaymentMethodItems < ActiveRecord::Migration
  def change
    add_column :payment_method_items, :refund, :boolean
    rename_column :drawer_transactions, :is_refund, :refund
    rename_column :order_items, :refund_payment_method, :refund_payment_method_item_id
  end
end
