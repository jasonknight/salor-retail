class CreatePaymentMethods < ActiveRecord::Migration
  def self.up
    create_table :payment_methods do |t|
      t.string :name,:internal_type
      t.float :amount, :default => 0.0
      t.references :order

      t.timestamps
    end
  end

  def self.down
    drop_table :payment_methods
  end
end
