class AddPaymentTotalToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :payment_total, :float
    add_column :orders, :noncash, :float
    rename_column :orders, :in_cash, :cash
  end
end
