class CreateSaleTypes < ActiveRecord::Migration
  def change
    create_table :sale_types do |t|
      t.string :name
      t.integer :vendor_id
      t.integer :user_id
      t.boolean :hidden

      t.timestamps
    end
  end
end
