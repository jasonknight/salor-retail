class AddAlwaysOpenDrawerToCashRegisters < ActiveRecord::Migration
  def change
    add_column :cash_registers, :always_open_drawer, :boolean
  end
end
