class CreateActions < ActiveRecord::Migration
  def self.up
    create_table :actions do |t|
      t.string :name
      t.text :code
      t.integer :vendor_id
      t.integer :user_id
      t.string :when

      t.timestamps
    end
  end

  def self.down
    drop_table :actions
  end
end
