class AddRebateAmountToOrderItem < ActiveRecord::Migration
  def change
    add_column :order_items, :rebate_amount, :float, :default => 0

  end
end
