class CreateDiscounts < ActiveRecord::Migration
  def self.up
    create_table :discounts do |t|
      t.string :name
      t.datetime :start_date
      t.datetime :end_date
      t.integer :vendor_id
      t.integer :category_id
      t.integer :location_id
      t.integer :item_sku
      t.string :applies_to

      t.timestamps
    end
  end

  def self.down
    drop_table :discounts
  end
end
