class CreateTransactionTags < ActiveRecord::Migration
  def self.up
    create_table :transaction_tags do |t|
      t.string :name
      t.integer :vendor_id

      t.timestamps
    end
  end

  def self.down
    drop_table :transaction_tags
  end
end
