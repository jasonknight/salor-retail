class AddRefundPaymentTypeToOrderItem < ActiveRecord::Migration
  def change
    add_column :order_items, :refund_payment_method, :string

  end
end
