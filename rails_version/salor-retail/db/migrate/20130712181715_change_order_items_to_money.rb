class ChangeOrderItemsToMoney < ActiveRecord::Migration
  def change
    puts "[RailsMoneyConversion] Editing the OrderItems table"
    fields = {
      :price => nil,
      :amount_remaining => :gift_card_amount, # renaming this column cause it is poorly named...
      :tax_amount => nil,
      :coupon_amount => nil,
      :discount_amount => nil,
      :rebate_amount => nil,
      :subtotal => nil,
      :total => nil
    }
    fields.each do |field,new_field|
      new_field = field if new_field.nil?
      add_column :order_items, "#{new_field}_cents", :integer, :default => 0
      add_column :order_items, "#{new_field}_currency", :string, :default => 'USD'
      OrderItem.connection.execute("update `order_items` set `#{new_field}_cents` = `#{field}` * 100")
      remove_column :order_items, field
    end
  end
end
