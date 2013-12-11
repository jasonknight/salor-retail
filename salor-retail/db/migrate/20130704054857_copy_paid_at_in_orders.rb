class CopyPaidAtInOrders < ActiveRecord::Migration
  def up
    
    # copy over created_at to paid_at
    Vendor.connection.execute("UPDATE orders SET paid_at=created_at")
    
    # add boolean flag since queries matching booleans are faster than matching strings. also the index will be smaller.
    Vendor.connection.execute("UPDATE drawer_transactions SET complete_order=TRUE WHERE tag = 'CompleteOrder'")
    
    # set those to nil because queries matchhing NULL are faster than matching floats
    change_column_default :order_items, :coupon_amount, nil
    change_column_default :order_items, :amount_remaining, nil
    change_column_default :order_items, :discount_amount, nil
    change_column_default :order_items, :rebate, nil
    change_column_default :order_items, :coupon_id, nil
    change_column_default :order_items, :rebate_amount, nil
    change_column_default :order_items, :price, nil
    change_column_default :order_items, :total, nil
    change_column_default :order_items, :tax, nil
    change_column_default :order_items, :tax_amount, nil
    
    change_column_default :orders, :rebate, nil
    change_column_default :orders, :lc_discount_amount, nil
    change_column_default :orders, :cash, nil
    change_column_default :orders, :rebate_type, nil
    
    change_column_default :payment_method_items, :amount, nil
    change_column_default :tax_profiles, :letter, nil
  end

  def down
  end
end
