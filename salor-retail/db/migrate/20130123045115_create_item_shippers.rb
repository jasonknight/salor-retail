class CreateItemShippers < ActiveRecord::Migration
  def change
    create_table :item_shippers do |t|
      t.references :shipper
      t.references :item
      t.float :purchase_price
      t.float :list_price
      t.string :item_sku
      t.string :shipper_sku

      t.timestamps
    end
    add_index :item_shippers, :shipper_id
    add_index :item_shippers, :item_id
  end
end
