class AddJournalToOrders < ActiveRecord::Migration
  def self.up
    add_column :orders, :j_text, :text
  end

  def self.down
    remove_column :orders, :j_text
  end
end
