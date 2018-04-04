class AddLogoutTimeToCashRegisterDailies < ActiveRecord::Migration
  def self.up
    add_column :cash_register_dailies, :logout_time, :datetime
  end

  def self.down
    remove_column :cash_register_dailies, :logout_time
  end
end
