class AddHiddenToOrderItems < ActiveRecord::Migration
  def change
    add_column :order_items, :hidden, :integer, :default => 0

  end
end
