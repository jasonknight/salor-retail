class ConvertDrawerTransactionsToMoney < ActiveRecord::Migration
  def change
    puts "[RailsMoneyConversion] Editing the Orders table"
    fields = [:amount,:drawer_amount]
    fields.each do |field|
      add_column :drawer_transactions, "#{field}_cents", :integer, :default => 0
      add_column :drawer_transactions, "#{field}_currency", :string, :default => 'USD'
      DrawerTransaction.connection.execute("update `drawer_transactions` set `#{field}_cents` = `#{field}` * 100")
      remove_column :drawer_transactions, field
    end
  end
end
