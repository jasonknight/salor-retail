class AddCouponToItems < ActiveRecord::Migration
  def self.up
    add_column :items, :coupon_type, :integer
    add_column :items, :coupon_applies, :string
  end

  def self.down
    remove_column :items, :coupon_applies
    remove_column :items, :coupon_type
  end
end
