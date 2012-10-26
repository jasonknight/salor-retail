class EnsureRebateNotNil < ActiveRecord::Migration
  def self.up
    change_column_default(:orders, :rebate,0)
    Order.connection.execute("update orders set rebate = 0 where rebate IS NULL")
  end

  def self.down
  end
end
