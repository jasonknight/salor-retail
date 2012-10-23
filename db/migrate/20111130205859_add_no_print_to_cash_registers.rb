class AddNoPrintToCashRegisters < ActiveRecord::Migration
  def self.up
    add_column :cash_registers, :no_print, :boolean, :default => false
  end

  def self.down
    remove_column :cash_registers, :no_print
  end
end
