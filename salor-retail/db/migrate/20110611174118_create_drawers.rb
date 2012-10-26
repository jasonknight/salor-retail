class CreateDrawers < ActiveRecord::Migration
  def self.up
    create_table :drawers do |t|
      t.float :amount, :default => 0
      t.integer :owner_id
      t.string :owner_type

      t.timestamps
    end
  end

  def self.down
    drop_table :drawers
  end
end
