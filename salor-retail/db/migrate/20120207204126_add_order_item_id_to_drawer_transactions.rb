class AddOrderItemIdToDrawerTransactions < ActiveRecord::Migration
  def change
    add_column :drawer_transactions, :order_item_id, :integer

  end
end
