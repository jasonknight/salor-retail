class AddDeviceNamesToCashRegisters < ActiveRecord::Migration
  def change
    add_column :cash_registers, :cash_drawer_name, :string
    add_column :cash_registers, :thermal_printer_name, :string
    add_column :cash_registers, :sticker_printer_name, :string
  end
end
