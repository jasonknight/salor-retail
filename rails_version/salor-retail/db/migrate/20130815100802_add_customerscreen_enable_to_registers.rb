class AddCustomerscreenEnableToRegisters < ActiveRecord::Migration
  def change
    add_column :cash_registers, :customerscreen_mode, :string
  end
end
