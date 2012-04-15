class AddPoleDisplayToCashRegister < ActiveRecord::Migration
  def self.up
    add_column :cash_registers, :pole_display, :string
  end

  def self.down
    remove_column :cash_registers, :pole_display
  end
end
