class AddIndices3 < ActiveRecord::Migration
  def change
    add_index :order_items, :completed_at
    add_index :order_items, :is_proforma
    add_index :order_items, :is_quote
    add_index :order_items, :total_cents
    add_index :order_items, :tax
    add_index :order_items, :activated
    
    add_index :payment_method_items, :completed_at
    add_index :payment_method_items, :is_proforma
    add_index :payment_method_items, :is_quote

    add_index :drawer_transactions, :created_at
    
    add_index :items, :child_id
  end
end
