class AddVendorIdToCashRegisters < ActiveRecord::Migration
  def self.up
    add_column :cash_registers, :vendor_id, :integer
  end

  def self.down
    remove_column :cash_registers, :vendor_id
  end
end
