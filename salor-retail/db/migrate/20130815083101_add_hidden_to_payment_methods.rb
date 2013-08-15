class AddHiddenToPaymentMethods < ActiveRecord::Migration
  def change
    add_column :payment_methods, :hidden_at, :datetime
    add_column :payment_methods, :hidden_by, :integer
  end
end
