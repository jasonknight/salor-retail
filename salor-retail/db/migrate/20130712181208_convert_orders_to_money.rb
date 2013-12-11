class ConvertOrdersToMoney < ActiveRecord::Migration
  def change
    puts "[RailsMoneyConversion] Editing the Orders table"
    fields = [:total, :subtotal, :tax_amount, :cash, :lc_amount, :change, :payment_total, :noncash, :rebate_amount]
    fields.each do |field|
      add_column :orders, "#{field}_cents", :integer, :default => 0
      add_column :orders, "#{field}_currency", :string, :default => 'USD'
      Order.connection.execute("update `orders` set `#{field}_cents` = `#{field}` * 100")
      remove_column :orders, field
    end
  end
end
