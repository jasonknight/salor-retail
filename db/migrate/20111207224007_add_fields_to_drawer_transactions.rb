class AddFieldsToDrawerTransactions < ActiveRecord::Migration
  def self.up
    add_column :drawer_transactions, :owner_id, :integer
    add_column :drawer_transactions, :owner_type, :string
  end

  def self.down
    remove_column :drawer_transactions, :owner_type
    remove_column :drawer_transactions, :owner_id
  end
end
