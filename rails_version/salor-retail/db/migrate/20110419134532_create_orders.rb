class CreateOrders < ActiveRecord::Migration
  def self.up
    create_table :orders do |t|
      t.float :subtotal
      t.float :total
      t.float :tax

      t.timestamps
    end
  end

  def self.down
    drop_table :orders
  end
end
