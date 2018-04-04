class AddAmountsToDiscounts < ActiveRecord::Migration
  def self.up
    add_column :discounts, :amount, :float
    add_column :discounts, :amount_type, :string
  end

  def self.down
    remove_column :discounts, :amount_type
    remove_column :discounts, :amount
  end
end
