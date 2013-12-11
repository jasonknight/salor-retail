class ConvertDrawersToMoney < ActiveRecord::Migration
  def change
    puts "[RailsMoneyConversion] Editing the Drawers table"
    fields = [:amount]
    fields.each do |field|
      add_column :drawers, "#{field}_cents", :integer, :default => 0
      add_column :drawers, "#{field}_currency", :string, :default => 'USD'
      DrawerTransaction.connection.execute("update `drawers` set `#{field}_cents` = `#{field}` * 100")
      remove_column :drawers, field
    end
  end
end
