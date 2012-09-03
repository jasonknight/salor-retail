class AddNotesToDrawerTransactions < ActiveRecord::Migration
  def self.up
    add_column :drawer_transactions, :notes, :text
  end

  def self.down
    remove_column :drawer_transactions, :notes
  end
end
