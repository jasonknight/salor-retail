class MigrateRefunds3 < ActiveRecord::Migration
  def up
    
    # README: Do not uncomment this, it is there to migrate over from the old system
    Vendor.all.each do |v|
      pm = v.payment_methods.visible.find_by_cash(true)
      if pm.nil?
        puts "WARNING: A PaymentMethod with the 'cash' flag is needed for vendor #{ v.id } to perform this operation. Skipping."
        next
      end
      v.order_items.where(:hidden => nil, :refunded => true).each do |oi|
        if oi.order.nil?
          puts "WARNING: OrderItem #{ oi.id } is not associated with an Order. Skipping."
          next
        end
        unless oi.order.payment_method_items.where(:refund => true).any?
          if oi.user.nil? or oi.order.user.nil?
            puts "WARNING: OrderItem #{ oi.id } AND its Order #{ oi.order.id } do not have a user_id or drawer_id attached. This is a bug in the old system and cannot be fixed. Skipping."
            next
          end
          pmi = PaymentMethodItem.new
          pmi.vendor = oi.vendor
          pmi.company = oi.company
          pmi.order = oi.order
          pmi.payment_method = pm
          pmi.user = oi.user
          pmi.drawer_id = oi.drawer_id
          pmi.drawer_id ||= oi.order.drawer_id
          pmi.drawer_id ||= oi.user.get_drawer.id
          pmi.drawer_id ||= oi.order.user.get_drawer.id
          pmi.refund = true
          pmi.cash = true
          pmi.cash_register = oi.order.cash_register
          pmi.amount_cents = oi.total_cents
          pmi.paid = oi.order.paid
          pmi.paid_at = oi.order.paid_at
          pmi.completed_at = oi.order.completed_at
          res = pmi.save
          raise "could not save PMI #{ pmi.errors.messages } for OrderItem #{ oi.id }." unless res == true
          pmi.update_attribute :created_at, oi.created_at
          puts "Adding refund cash PM #{ pmi.amount_cents} to order #{ oi.order_id }"
        else
          puts "OrderItem #{ oi.id } already has a refund payment method item. Doing nothing."
        end
      end
    end
    
    puts "set amounts to zero for refunded OIs since that is the new convention"
    OrderItem.connection.execute("UPDATE order_items SET total_cents = 0, tax_amount_cents = 0, rebate_amount_cents = 0, discount_amount_cents = 0, coupon_amount_cents = 0 WHERE refunded IS TRUE")
  end

  def down
  end
end
