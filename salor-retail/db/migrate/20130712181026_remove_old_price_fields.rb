class RemoveOldPriceFields < ActiveRecord::Migration
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
      remove_column :items, field
    end
  end
end
