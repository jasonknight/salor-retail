class CreateBrokenItems < ActiveRecord::Migration
  def self.up
    create_table :broken_items do |t|
      t.string :name
      t.string :sku
      t.float :quantity, :defalut => 0.0
      t.float :base_price, :defalut => 0.0
      t.integer :vendor_id
      t.integer :owner_id
      t.integer :shipper_id
      t.string :owner_type
      t.text :note

      t.timestamps
    end
  end

  def self.down
    drop_table :broken_items
  end
end
