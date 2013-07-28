class AddMoreToInventoryReportItems < ActiveRecord::Migration
  def change
    add_column :inventory_report_items, :category_id, :integer
    add_column :inventory_report_items, :purchase_price_cents, :integer
    add_column :inventory_report_items, :price_cents, :integer
  end
  rename_column :inventory_report_items, :item_quantity, :quantity
end
