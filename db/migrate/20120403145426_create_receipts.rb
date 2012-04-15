class CreateReceipts < ActiveRecord::Migration
  def change
    create_table :receipts do |t|
      t.string :ip
      t.integer :employee_id,:cash_register_id
      t.text :content

      t.timestamps
    end
  end
end
