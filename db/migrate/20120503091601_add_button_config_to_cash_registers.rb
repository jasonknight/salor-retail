class AddButtonConfigToCashRegisters < ActiveRecord::Migration
  def change
    add_column :cash_registers, :hide_buttons, :boolean,:default => true

  end
end
