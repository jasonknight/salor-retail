class ConvertBrokenItemsToMoney < ActiveRecord::Migration
  def change
    puts "[RailsMoneyConversion] Editing the BrokenItems table"
    fields = {
      :base_price => :price
    }
    fields.each do |field,new_field|
      add_column :broken_items, "#{new_field}_cents", :integer, :default => 0
      add_column :broken_items, "#{new_field}_currency", :string, :default => 'USD'
      Item.connection.execute("update `broken_items` set `#{new_field}_cents` = `#{field}` * 100")
      remove_column :broken_items, field
    end
  end
end
