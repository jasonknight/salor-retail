class AddRequirePasswordToCashRegisters < ActiveRecord::Migration
  def change
    add_column :cash_registers, :require_password, :boolean
  end
end
