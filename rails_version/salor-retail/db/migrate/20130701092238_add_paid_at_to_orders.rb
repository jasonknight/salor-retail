class AddPaidAtToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :paid_at, :datetime
  end
end
