class RenameFieldsOnOrderItems < ActiveRecord::Migration
  def change
    rename_column :order_items, :discount_applied, :discount_applies
    rename_column :order_items, :coupon_applied, :coupon_applies
  end
end
