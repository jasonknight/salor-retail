class AddScaleNameToCashRegisters < ActiveRecord::Migration
  def change
    add_column :cash_registers, :scale_name, :string
  end
end
