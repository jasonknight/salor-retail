class AddVendorIdToPaymentMethods < ActiveRecord::Migration
  def change
    add_column :payment_methods, :vendor_id, :integer
  end
end
