class CreateItems < ActiveRecord::Migration
  def self.up
    create_table :items do |t|
      t.string :name
      t.text :description
      t.string :sku
      t.string :image
      t.integer :vendor_id

      t.timestamps
    end
  end

  def self.down
    drop_table :items
  end
end
