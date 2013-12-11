class AddTaxFreeToOrdersAndOrderItems < ActiveRecord::Migration
  def change
    add_column :orders,:tax_free, :boolean, :default => false
    add_column :order_items,:tax_free, :boolean, :default => false
  end
end
