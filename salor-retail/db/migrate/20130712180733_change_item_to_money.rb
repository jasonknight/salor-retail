class ChangeItemToMoney < ActiveRecord::Migration
  def change
    puts "[RailsMoneyConversion] Editing the Items table"
    fields = {
      :base_price => :price,
      :amount_remaining => :gift_card_amount, # renaming this column cause it is poorly named...
      :purchase_price => :purchase_price,
      :buyback_price => :buy_price,
      :manufacturer_price => :manufacturer_price
    }
    fields.each do |field,new_field|
      add_column :items, "#{new_field}_cents", :integer, :default => 0
      add_column :items, "#{new_field}_currency", :string, :default => 'USD'
      Item.connection.execute("update `items` set `#{new_field}_cents` = `#{field}` * 100")
    end
  end
end
