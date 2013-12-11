class AddSubscriptionToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :payment_due, :datetime
    add_column :orders, :subscription, :boolean
    add_column :orders, :subscription_interval, :integer
    add_column :orders, :subscription_order_id, :integer
    add_column :orders, :subscription_start, :datetime
  end
end
