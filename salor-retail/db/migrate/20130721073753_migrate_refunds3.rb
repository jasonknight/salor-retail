class MigrateRefunds3 < ActiveRecord::Migration
  def up
    
    # README: Do not uncomment this, it is there to migrate over from the old system
    Vendor.all.each do |v|
      pm = v.payment_methods.visible.find_by_cash(true)
      v.order_items.visible.where(:refunded => true).each do |oi|
        next if oi.order.nil?
        unless oi.order.payment_method_items.where(:refund => true).any?
          pmi = PaymentMethodItem.new
          pmi.vendor = oi.vendor
          pmi.company = oi.company
          pmi.order = oi.order
          pmi.payment_method = pm
          pmi.user = oi.user
          pmi.drawer = oi.drawer
          pmi.refund = true
          pmi.cash = true
          pmi.created_at = oi.created_at
          pmi.amount_cents = oi.total_cents
          res = pmi.save(:validate => false)
          raise "could not save pmi #{ pmi.errors.messages }" unless res == true
          puts "Adding refund change PM #{ pmi.amount_cents} to order #{ oi.order_id }"
        end
      end
    end
    
    puts "set amounts to zero for refunded OIs since that is the new convention"
    OrderItem.connection.execute("UPDATE order_items SET total_cents = 0, tax_amount_cents = 0, rebate_amount_cents = 0, discount_amount_cents = 0, coupon_amount_cents = 0 WHERE refunded IS TRUE")
  end

  def down
  end
end
