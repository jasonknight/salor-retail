class MigrateRefunds2 < ActiveRecord::Migration
  def up    
    OrderItem.reset_column_information
    
    # in the old refund system, a DT was created for cash refunds, and a PM for noncash refunds. However, we want PMs also for cash refunds, so we add them now based on refund DT.
    DrawerTransaction.where(:refund => true).each do |dt|
      order = dt.order
      
      next if order.nil?
      puts "processing DrawerTransaction ID #{ dt.id } order_id #{ order.id }"
      vendor = order.vendor
      
      pm = vendor.payment_methods.visible.where(:cash => true).first
      
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
      res = pmi.save(:validate => false)
      raise "Could not save PMI #{ pmi.errors.messages }" unless res == true
      
      oi_id = dt.notes.to_s.gsub('#', '').to_i
      oi = OrderItem.find_by_id(oi_id)
      oi.update_attribute :refund_payment_method_item_id, pmi.id

    end
  end

  def down
  end
end
