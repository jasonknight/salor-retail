class AddRefundFields < ActiveRecord::Migration
  def self.up
    add_column(:order_items,:refunded_at, :datetime)
    add_column(:orders,:refunded_at, :datetime)
    add_column(:order_items,:refunded_by, :integer)
    add_column(:orders,:refunded_by, :integer)
    add_column(:order_items,:refunded_by_type, :string)
    add_column(:orders,:refunded_by_type, :string)
  end

  def self.down
    drop_column(:order_items,:refunded_at)
    drop_column(:orders,:refunded_at)
    drop_column(:order_items,:refunded_by)
    drop_column(:orders,:refunded_by)
    drop_column(:order_items,:refunded_by_type)
    drop_column(:orders,:refunded_by_type)
  end
end
