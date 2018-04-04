class AddDetailedEditToCashRegisters < ActiveRecord::Migration
  def change
    add_column :cash_registers, :detailed_edit, :boolean
  end
end
