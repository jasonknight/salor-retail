class AddScaleToRegisters < ActiveRecord::Migration
  def self.up
    add_column :cash_registers, :scale, :string
  end

  def self.down
    remove_column :cash_registers, :scale
  end
end
