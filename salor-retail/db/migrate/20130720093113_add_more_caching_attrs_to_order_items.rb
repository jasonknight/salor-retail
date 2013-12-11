class AddMoreCachingAttrsToOrderItems < ActiveRecord::Migration
  def change
    add_column :order_items, :is_quote, :boolean
    add_column :order_items, :is_unpaid, :boolean
    add_column :order_items, :paid, :boolean
    add_column :order_items, :paid_at, :datetime
  end
end
