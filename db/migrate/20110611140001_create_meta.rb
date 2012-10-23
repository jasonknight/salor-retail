class CreateMeta < ActiveRecord::Migration
  def self.up
    create_table :meta do |t|
      t.integer :vendor_id
      t.integer :crd_id
      t.integer :order_id
      t.integer :ownable_id
      t.string :ownable_type

      t.timestamps
    end
  end

  def self.down
    drop_table :meta
  end
end
