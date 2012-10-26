class AddPrinterFieldsToCashRegisters < ActiveRecord::Migration
  def self.up
    add_column :cash_registers, :thermal_printer, :string
    add_column :cash_registers, :sticker_printer, :string
    add_column :cash_registers, :a4_printer, :string
    Vendor.all.each do |vendor|
      thermal = vendor.vendor_printers.where(:printer_type => 'escpos').first
      sticker = vendor.vendor_printers.where(:printer_type => 'slcs').first
      if thermal then
        thermal.cash_register.update_attribute :thermal_printer,thermal.path
      end
      if sticker then
        sticker.cash_register.update_attribute :sticker_printer,sticker.path
      end
    end
  end

  def self.down
    remove_column :cash_registers, :a4_printer
    remove_column :cash_registers, :sticker_printer
    remove_column :cash_registers, :thermal_printer
  end
end
