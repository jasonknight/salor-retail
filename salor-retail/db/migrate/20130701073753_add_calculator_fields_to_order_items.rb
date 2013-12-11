class AddCalculatorFieldsToOrderItems < ActiveRecord::Migration
  def up
    add_column :order_items, :discount, :float
    add_column :order_items, :subtotal, :float
    
    rename_column :order_items, :tax, :tax_amount
    rename_column :order_items, :tax_profile_amount, :tax
    
    remove_column :order_items, :refunded_by_type
    remove_column :order_items, :total_is_locked
    remove_column :order_items, :tax_is_locked
    remove_column :order_items, :tax_free
    remove_column :order_items, :coupon_applies
  end
  
  def down
  end
end
