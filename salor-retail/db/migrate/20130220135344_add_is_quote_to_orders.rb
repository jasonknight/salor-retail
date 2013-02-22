class AddIsQuoteToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :is_quote, :boolean, :default => false
  end
end
