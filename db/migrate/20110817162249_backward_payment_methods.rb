class BackwardPaymentMethods < ActiveRecord::Migration
  def self.up
    PaymentMethod.reset_column_information
    Order.all.each do |o|
      if o.paid and not o.payment_methods.any? then
        if not o.in_cash.nil? and o.in_cash > 0 then
          pm = PaymentMethod.new({:internal_type => "ByCash", :amount => o.in_cash})
          pm.order_id = o.id
          pm.save
        end
        if not o.in_cash.nil? and o.by_card > 0 then
          pm = PaymentMethod.new({:internal_type => "ByCard", :amount => o.by_card})
          pm.order_id = o.id
          pm.save
        end
      end
    end
  end

  def self.down
  end
end
