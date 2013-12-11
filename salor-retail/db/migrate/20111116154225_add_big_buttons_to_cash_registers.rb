class AddBigButtonsToCashRegisters < ActiveRecord::Migration
  def self.up
    add_column :cash_registers, :big_buttons, :boolean, :default => false
    add_column :cash_registers, :hide_discounts, :boolean, :default => false
  end

  def self.down
    remove_column :cash_registers, :hide_discounts
    remove_column :cash_registers, :big_buttons
  end
end
