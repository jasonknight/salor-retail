class AddHiddenToDiscounts < ActiveRecord::Migration
  def self.up
    add_column :discounts, :hidden, :boolean
  end

  def self.down
    remove_column :discounts, :hidden
  end
end
