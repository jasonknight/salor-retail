class MigrateRefunds3 < ActiveRecord::Migration
  def up
    puts "set amounts to zero for refunded OIs since that is the new convention"
    OrderItem.connection.execute("UPDATE order_items SET total_cents = 0, tax_amount_cents = 0, rebate_amount_cents = 0, discount_amount_cents = 0, coupon_amount_cents = 0 WHERE refunded IS TRUE")
    
    puts "re-calculate Order totals which contain refunded OrderItems"
    oids = OrderItem.where(:refunded => true).collect { |oi| oi.order_id }.uniq
    Order.where(:id => oids).each { |o| o.calculate_totals }
  end

  def down
  end
end
