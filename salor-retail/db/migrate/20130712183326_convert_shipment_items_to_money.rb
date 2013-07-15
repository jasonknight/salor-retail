class ConvertShipmentItemsToMoney < ActiveRecord::Migration
  def change
    puts "[RailsMoneyConversion] Editing the ShipmentItems table"
    fields = {
      :base_price => :price,
      :purchase_price => :purchase_price
    }
    fields.each do |field,new_field|
      add_column :shipment_items, "#{new_field}_cents", :integer, :default => 0
      add_column :shipment_items, "#{new_field}_currency", :string, :default => 'USD'
      Item.connection.execute("update `shipment_items` set `#{new_field}_cents` = `#{field}` * 100")
      remove_column :shipment_items, field
    end
  end
end
