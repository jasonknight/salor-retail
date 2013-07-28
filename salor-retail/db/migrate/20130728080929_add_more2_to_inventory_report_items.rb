class AddMore2ToInventoryReportItems < ActiveRecord::Migration
  def change
    add_column :inventory_report_items, :name, :string
    add_column :inventory_report_items, :sku, :string
  end
end
