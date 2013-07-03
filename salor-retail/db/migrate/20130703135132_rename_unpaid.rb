class RenameUnpaid < ActiveRecord::Migration
  def up
    rename_column :orders, :unpaid_invoice, :is_unpaid
    add_column :payment_methods, :unpaid, :boolean
    add_column :payment_methods, :quote, :boolean
    add_column :payment_method_items, :unpaid, :boolean
    add_column :payment_method_items, :quote, :boolean
  end

  def down
  end
end
