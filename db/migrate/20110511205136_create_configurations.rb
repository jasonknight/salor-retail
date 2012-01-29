class CreateConfigurations < ActiveRecord::Migration
  def self.up
    create_table :configurations do |t|
      t.integer :vendor_id
      t.float :lp_per_dollar
      t.float :dollar_per_lp
      t.text :address
      t.string :telephone
      t.text :receipt_blurb

      t.timestamps
    end
  end

  def self.down
    drop_table :configurations
  end
end
