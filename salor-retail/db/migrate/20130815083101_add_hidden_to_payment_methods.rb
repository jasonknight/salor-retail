class AddHiddenToPaymentMethods < ActiveRecord::Migration
  def change
    begin
    add_column :payment_methods, :hidden_at, :datetime
    add_column :payment_methods, :hidden_by, :integer
    rescue
    end
  end
end
