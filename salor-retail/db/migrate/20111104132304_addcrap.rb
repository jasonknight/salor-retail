class Addcrap < ActiveRecord::Migration
  def self.up
    add_column :cash_registers, :artema_hybrid, :boolean, :default => false
    add_column :cash_registers, :bank_machine_path, :string
    add_column :cash_registers, :cash_drawer_path, :string 
  end

  def self.down
    remove_column :cash_registers, :bank_machine_path
    remove_column :cash_registers, :artema_hybrid
    remove_column :cash_registers, :cash_drawer_path 
  end
end
