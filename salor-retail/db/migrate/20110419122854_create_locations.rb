class CreateLocations < ActiveRecord::Migration
  def self.up
    create_table :locations do |t|
      t.string :name
      t.float :x
      t.float :y
      t.string :shape
      t.integer :vendor_id

      t.timestamps
    end
  end

  def self.down
    drop_table :locations
  end
end
