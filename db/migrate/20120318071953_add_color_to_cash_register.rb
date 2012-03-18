class AddColorToCashRegister < ActiveRecord::Migration
  def change
    add_column :cash_registers, :color, :string

  end
end
