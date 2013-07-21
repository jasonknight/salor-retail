class AddMoreCachingAttrsToPaymentMethodItems < ActiveRecord::Migration
  def change
    add_column :payment_method_items, :is_proforma, :boolean
    add_column :payment_method_items, :is_quote, :boolean
    add_column :payment_method_items, :is_unpaid, :boolean
    add_column :payment_method_items, :paid, :boolean
    add_column :payment_method_items, :paid_at, :datetime
    add_column :payment_method_items, :completed_at, :datetime
  end
end
