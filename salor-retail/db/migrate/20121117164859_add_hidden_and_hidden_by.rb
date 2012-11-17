class AddHiddenAndHiddenBy < ActiveRecord::Migration
  def up
    [ Order,OrderItem,SaleType,TenderMethod,Item,Shipper,Shipment,DrawerTransaction,Action, BrokenItem,Category,Country,Customer,Discount,
     Location,ShipmentType,StockLocation,TaxProfile,TransactionTag,Vendor].each do |model|
      m = model.send(:new)
      if not m.respond_to? :hidden then
        puts "Adding :hidden column :boolean to #{m.class.table_name}"
        add_column m.class.table_name.to_sym, :hidden, :boolean
      end
      
      if not m.respond_to? :hidden_by then
        puts "Adding :hidden_by column to #{m.class.table_name}"
        add_column m.class.table_name.to_sym, :hidden_by, :integer
      end
      
    end
    
  end

  def down
  end
end
