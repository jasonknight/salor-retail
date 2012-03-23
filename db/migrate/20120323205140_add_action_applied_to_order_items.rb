class AddActionAppliedToOrderItems < ActiveRecord::Migration
  def change
    add_column :order_items, :action_applied, :boolean, :default => false

  end
end
