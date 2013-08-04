class AddMoreSubscriptionToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :subscription_next, :datetime
    add_column :orders, :subscription_last, :datetime
  end
end
