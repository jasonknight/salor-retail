class CreateCashRegisters < ActiveRecord::Migration
  def self.up
    create_table :cash_registers do |t|
      t.string :name
      t.timestamps
    end
  end

  def self.down
    drop_table :cash_registers
  end
end
