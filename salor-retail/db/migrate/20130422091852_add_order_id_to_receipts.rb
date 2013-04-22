class AddOrderIdToReceipts < ActiveRecord::Migration
  def change
    add_column :receipts, :order_id, :integer
  end
end
