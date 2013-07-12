class ConvertShipmentsToMoney < ActiveRecord::Migration
  def change
    puts "[RailsMoneyConversion] Editing the Shipments table"
    fields = [:price]
    fields.each do |field|
      add_column :shipments, "#{field}_cents", :integer, :default => 0
      add_column :shipments, "#{field}_currency", :string, :default => 'USD'
      Shipment.connection.execute("update `shipments` set `#{field}_cents` = `#{field}` * 100")
      remove_column :shipments, field
    end
  end
end
