class AddHiddenToCashRegisters < ActiveRecord::Migration
  def self.up
    add_column :cash_registers, :hidden, :boolean, :default => false
  end

  def self.down
    remove_column :cash_registers, :hidden
  end
end
