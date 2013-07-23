class AddPositionToPaymentMethods < ActiveRecord::Migration
  def change
    add_column :payment_methods, :position, :integer
  end
end
