class AddCurrencyToInventoryReportItems < ActiveRecord::Migration
  def change
    add_column :inventory_report_items, :currency, :string
  end
end
