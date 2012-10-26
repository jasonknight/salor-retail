class AddAddressToCashRegisters < ActiveRecord::Migration
  def change
    add_column :cash_registers, :ip, :string

  end
end
