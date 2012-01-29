class CreateLoyaltyCards < ActiveRecord::Migration
  def self.up
    create_table :loyalty_cards do |t|
      t.integer :points
      t.integer :num_swipes
      t.integer :num_used
      t.integer :customer_id

      t.timestamps
    end
  end

  def self.down
    drop_table :loyalty_cards
  end
end
