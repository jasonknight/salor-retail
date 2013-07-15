class ChangesForReports2 < ActiveRecord::Migration
  def change
    add_column :payment_method_items, :cash, :boolean
    add_column :payment_method_items, :change, :boolean
    add_column :payment_methods, :cash, :boolean
    add_column :payment_methods, :change, :boolean
  end
end
