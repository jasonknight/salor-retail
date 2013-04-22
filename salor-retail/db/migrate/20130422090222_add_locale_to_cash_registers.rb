class AddLocaleToCashRegisters < ActiveRecord::Migration
  def change
    add_column :cash_registers, :locale, :string
  end
end
