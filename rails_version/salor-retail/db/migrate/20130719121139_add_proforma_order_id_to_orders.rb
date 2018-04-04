class AddProformaOrderIdToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :proforma_order_id, :integer
  end
end
