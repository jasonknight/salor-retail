class AddCalculatePartPriceToOrderItems < ActiveRecord::Migration
  def change
    add_column :order_items, :calculate_part_price, :boolean
  end
end
