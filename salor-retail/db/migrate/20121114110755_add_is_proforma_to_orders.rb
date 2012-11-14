class AddIsProformaToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :is_proforma, :boolean, :default => false
  end
end
