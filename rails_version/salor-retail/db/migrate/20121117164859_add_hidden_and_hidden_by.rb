class AddHiddenAndHiddenBy < ActiveRecord::Migration
  def up
    [ Order,OrderItem,SaleType,Item,Shipper,Shipment,DrawerTransaction,Action, BrokenItem,Category,Country,Customer,Discount,
     Location,ShipmentType,StockLocation,TaxProfile,TransactionTag,Vendor].each do |model|
      model.reset_column_information
      #m = model.send(:new)
      if not model.column_names.include? 'hidden' then
        puts "Adding :hidden column :boolean to #{model}"
        add_column model.table_name.to_sym, :hidden, :boolean
      end
      
      if not model.column_names.include? 'hidden_by' then
        puts "Adding :hidden_by column to #{model}"
        add_column model.table_name.to_sym, :hidden_by, :integer
      end
      
    end
    
  end

  def down
  end
end
