class AddTaxProfileIdToInventoryReportItems < ActiveRecord::Migration
  def change
    add_column :inventory_report_items, :tax_profile_id, :integer
  end
end
