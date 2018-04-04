class MigrateRefunds2 < ActiveRecord::Migration
  def up
    
    begin
      # this is weird because it is already added in migration 20130714065759, but it didn't do it, so we do it again.
      add_column :order_items, :refund_payment_method_item_id, :integer
    rescue
    end
    
    OrderItem.reset_column_information
    
    # in the old refund system, a DT was created for cash refunds, and a PM for noncash refunds. However, we want PMs also for cash refunds, so we add them now based on refund DT.
    DrawerTransaction.where(:refund => true).each do |dt|
      order = dt.order
      
      if order.nil?
        puts "WARNING: DrawerTransaction #{ dt.id } is not associated with an Order. This is a bug in the old system and cannot be fixed. Skipping."
        next
      end
      
      vendor = order.vendor
      puts "Creating refund PMI from refund DrawerTransaction ID #{ dt.id } order_id #{ order.id }, vendor_id #{ vendor.id }"
      
      
      pm = vendor.payment_methods.visible.where(:cash => true).first
      
      if pm.nil?
        puts "WARNING: Vendor #{ vendor.id } does not have a cash PaymentMethod. Skipping."
        next
      end
      
      pmi = PaymentMethodItem.new
      pmi.vendor = order.vendor
      pmi.company = order.company
      pmi.order = order
      pmi.user = order.user
      pmi.drawer = order.drawer
      pmi.payment_method = pm
      pmi.cash = true
      pmi.refund = true
      pmi.cash_register = order.cash_register
      pmi.amount_cents = dt.amount_cents
      pmi.internal_type = "InCashRefund"
      res = pmi.save
      pmi.created_at = order.created_at
      res = pmi.save
      raise "Could not save PMI #{ pmi.errors.messages }" unless res == true
      
      # make an association between PMI and OI based on the Note that the old system added.
      oi_id = dt.notes.to_s.gsub('#', '').to_i
      oi = OrderItem.find_by_id(oi_id)
      if oi.nil?
        puts "WARNING: DT #{ dt.is } lists #{ dt.notes } as matching OI, but it could not be found in the DB. Cannot make association."
      else
        oi.refund_payment_method_item_id = pmi.id
        oi.drawer_id = oi.order.drawer_id
        oi.drawer_id ||= oi.user.get_drawer.id
        oi.user_id ||= oi.order.user_id
        res = oi.save
        raise "Could not save OrderItem #{ oi.inspect } because #{ oi.errors.messages }." unless res == true
      end

    end
  end

  def down
  end
end
