class CreateInventoryReports < ActiveRecord::Migration
  def change
    create_table :inventory_reports do |t|
      t.string :name

      t.timestamps
    end
  end
end
