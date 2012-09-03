class SetDefaultRebateType < ActiveRecord::Migration
  def self.up
    change_column_default(:orders, :rebate_type,'percent')
  end

  def self.down
  end
end
