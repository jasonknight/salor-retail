class AddDtTagToDrawerTransactions < ActiveRecord::Migration
  def self.up
    add_column :drawer_transactions, :tag, :string, :default => 'None'
  end

  def self.down
    remove_column :drawer_transactions, :tag
  end
end
