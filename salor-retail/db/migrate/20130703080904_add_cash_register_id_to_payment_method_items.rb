class AddCashRegisterIdToPaymentMethodItems < ActiveRecord::Migration
  def change
    add_column :payment_method_items, :cash_register_id, :integer
    
    Vendor.connection.execute("UPDATE payment_method_items,orders SET payment_method_items.cash_register_id = orders.cash_register_id WHERE orders.id = payment_method_items.order_id")
  end
end
