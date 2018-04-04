class AddCompleteOrderToDrawerTransactions < ActiveRecord::Migration
  def change
    add_column :drawer_transactions, :complete_order, :boolean
  end
end
