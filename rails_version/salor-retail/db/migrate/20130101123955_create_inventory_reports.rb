class CreateInventoryReports < ActiveRecord::Migration
  def change
    begin
    create_table :inventory_reports do |t|
      t.string :name

      t.timestamps
    end
    rescue

    end
  end
end
