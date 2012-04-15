class AddCustomerSkuToLoyaltyCards < ActiveRecord::Migration
  def change
    begin
      add_column :loyalty_cards, :customer_sku, :string
    rescue
      puts $!.inspect
    end
    LoyaltyCard.all.each do |lc|
    next if lc.customer.nil?
      lc.update_attribute :customer_sku, lc.customer.sku
    end
  end
end
