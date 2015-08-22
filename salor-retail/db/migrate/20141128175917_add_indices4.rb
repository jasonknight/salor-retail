class AddIndices4 < ActiveRecord::Migration
  def change
    add_index :drawer_transactions, :order_id
  end
end
