class CreateInventoryReportItems < ActiveRecord::Migration
  def change
    begin
    create_table :inventory_report_items do |t|
      t.references :inventory_report
      t.references :item
      t.float :real_quantity
      t.float :item_quantity

      t.timestamps
    end
rescue

end
begin
    add_index :inventory_report_items, :inventory_report_id
    add_index :inventory_report_items, :item_id
rescue

end
  end
end
