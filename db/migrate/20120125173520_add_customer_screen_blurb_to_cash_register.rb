class AddCustomerScreenBlurbToCashRegister < ActiveRecord::Migration
  def self.up
    add_column :cash_registers, :customer_screen_blurb, :string
  end

  def self.down
    remove_column :cash_registers, :customer_screen_blurb
  end
end
