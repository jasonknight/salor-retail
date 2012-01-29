class AddCashRegisterDailyIdToOrders < ActiveRecord::Migration
  def self.up
    add_column :orders, :cash_register_daily_id, :integer
  end

  def self.down
    remove_column :orders, :cash_register_daily_id
  end
end
