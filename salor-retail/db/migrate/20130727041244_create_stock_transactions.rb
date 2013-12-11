class CreateStockTransactions < ActiveRecord::Migration
  def change
    create_table :stock_transactions do |t|
      t.integer :company_id
      t.integer :vendor_id
      t.integer :user_id
      t.integer :cash_register_id
      t.integer :order_id
      t.integer :from_id
      t.string  :from_type
      t.integer :to_id
      t.integer :to_type
      t.float   :from_quantity
      t.float   :to_quantity
      t.float   :quantity
      t.boolean :hidden
      t.integer :hidden_by
      t.datetime :hidden_at

      t.timestamps
    end
  end
end
