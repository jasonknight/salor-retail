class ChangeOrderAttributes < ActiveRecord::Migration
  def up
    change_column_default :orders, :front_end_change, nil
    rename_column :orders, :front_end_change, :change
    remove_column :orders, :refunded
    remove_column :orders, :total_is_locked
    remove_column :orders, :tax_is_locked
    remove_column :orders, :subtotal_is_locked
    remove_column :orders, :cash_register_daily_id
    remove_column :orders, :by_card
    remove_column :orders, :refunded_at
    remove_column :orders, :refunded_by
    remove_column :orders, :refunded_by_type
    remove_column :orders, :discount_amount
    remove_column :orders, :tax_free
    change_column_default :orders, :qnr, nil
  end

  def down
  end
end
