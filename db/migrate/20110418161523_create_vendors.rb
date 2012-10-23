class CreateVendors < ActiveRecord::Migration
  def self.up
    create_table :vendors do |t|
      t.string :name
      t.integer :user_id
      t.text :description

      t.timestamps
    end
  end

  def self.down
    drop_table :vendors
  end
end
