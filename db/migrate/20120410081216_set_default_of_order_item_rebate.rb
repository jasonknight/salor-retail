class SetDefaultOfOrderItemRebate < ActiveRecord::Migration
  def up
    change_column_default :order_items, :rebate, 0.0
  end

  def down
  end
end
