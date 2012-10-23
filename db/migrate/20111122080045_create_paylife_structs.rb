class CreatePaylifeStructs < ActiveRecord::Migration
  def self.up
    create_table :paylife_structs do |t|
      t.string :owner_type
      t.integer :owner_id
      t.integer :vendor_id
      t.integer :cash_register_id
      t.integer :order_id
      t.text :struct
      t.text :json
      t.boolean :tes, :default => false
      t.timestamps
    end
  end

  def self.down
    drop_table :paylife_structs
  end
end
