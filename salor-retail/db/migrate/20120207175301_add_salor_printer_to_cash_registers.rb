class AddSalorPrinterToCashRegisters < ActiveRecord::Migration
  def change
    add_column :cash_registers, :salor_printer, :boolean,:default => false

  end
end
