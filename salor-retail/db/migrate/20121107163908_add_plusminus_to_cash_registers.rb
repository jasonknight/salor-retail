class AddPlusminusToCashRegisters < ActiveRecord::Migration
  def change
    begin
      add_column :cash_registers, :show_plus_minus, :boolean, :default => true
    rescue
      puts $!.inspect
    end
  end
end
