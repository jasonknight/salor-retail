class ConvertPaymentMethodItemsToMoney < ActiveRecord::Migration
  def up
    puts "[RailsMoneyConversion] Editing the PaymentMethodItem table"
    fields = [:amount]
    fields.each do |field|
      add_column :payment_method_items, "#{field}_cents", :integer, :default => 0
      add_column :payment_method_items, "#{field}_currency", :string, :default => 'USD'
      PaymentMethodItem.connection.execute("update `payment_method_items` set `#{field}_cents` = `#{field}` * 100")
      remove_column :payment_method_items, field
    end
  end

  def down
  end
end
