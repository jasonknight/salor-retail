class AddShowPlusMinusToCashRegisters < ActiveRecord::Migration
  def change
    add_column :cash_registers, :show_plus_minus, :boolean,:default => true
  end
end
