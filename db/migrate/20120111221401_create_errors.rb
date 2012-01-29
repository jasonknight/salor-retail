class CreateErrors < ActiveRecord::Migration
  def self.up
    create_table :errors do |t|
      t.text :msg
      t.references :vendor
      t.string :owner_type
      t.integer :owner_id
      t.string :applies_to_type
      t.integer :applies_to_id
      t.boolean :seen, :default => false
      t.timestamps
    end
  end

  def self.down
    drop_table :errors
  end
end
