class AddAmountRemainingToItems < ActiveRecord::Migration
  def self.up
    add_column :items, :amount_remaining, :float, :default => 0
  end

  def self.down
    remove_column :items, :amount_remaining
  end
end
