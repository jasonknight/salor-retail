class MigrateRefunds < ActiveRecord::Migration
  def up
    
    rename_column :order_items, :refund_payment_method_item_id, :refund_payment_method_internal_type
    
    add_column :order_items, :refund_payment_method_item_id, :integer
    
    
      
  end

  def down
  end
end
