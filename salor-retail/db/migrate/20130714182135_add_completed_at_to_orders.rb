class AddCompletedAtToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :completed_at, :datetime
    add_column :order_items, :completed_at, :datetime
  end
end
