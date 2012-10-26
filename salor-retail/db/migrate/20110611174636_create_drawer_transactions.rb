class CreateDrawerTransactions < ActiveRecord::Migration
  def self.up
    create_table :drawer_transactions do |t|
      t.integer :drawer_id
      t.float :amount
      t.boolean :drop
      t.boolean :payout

      t.timestamps
    end
  end

  def self.down
    drop_table :drawer_transactions
  end
end
