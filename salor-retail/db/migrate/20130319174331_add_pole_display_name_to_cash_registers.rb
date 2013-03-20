class AddPoleDisplayNameToCashRegisters < ActiveRecord::Migration
  def change
    add_column :cash_registers, :pole_display_name, :string
  end
end
