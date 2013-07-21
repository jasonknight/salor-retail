class AddIsProformaToOrderItems < ActiveRecord::Migration
  def change
    add_column :order_items, :is_proforma, :boolean
  end
end
