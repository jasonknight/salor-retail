class AddCouponAppliesToOrderItems < ActiveRecord::Migration
  def change
    add_column :order_items, :coupon_applies, :string
  end
end
