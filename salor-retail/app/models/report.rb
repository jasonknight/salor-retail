# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class Report
  def dump_all(from,to)
    tfrom = from.strftime("%Y%m%d")
    tto = to.strftime("%Y%m%d")
    from = from.strftime("%Y-%m-%d 01:00:00")
    to = to.strftime("%Y-%m-%d 23:59:59")
    @orders = Order.where(["(created_at BETWEEN ? AND ?) OR (updated_at BETWEEN ? AND ?)",from,to,from,to]).order("created_at DESC")
    @items = Item.where(["(created_at BETWEEN ? AND ?) OR (updated_at BETWEEN ? AND ?)",from,to,from,to]).order("created_at DESC")
    @histories = History.where(["(created_at BETWEEN ? AND ?) OR (updated_at BETWEEN ? AND ?)",from,to,from,to]).order("created_at DESC")
    @drawer_transactions = DrawerTransaction.where(["(created_at BETWEEN ? AND ?) OR (updated_at BETWEEN ? AND ?)",from,to,from,to]).order("created_at DESC")
    @receipts = Receipt.where(["(created_at BETWEEN ? AND ?) OR (updated_at BETWEEN ? AND ?)",from,to,from,to]).order("created_at DESC")

    File.open(File.join('/', 'tmp', 'SalorOrders.tsv'),"w") do |f|
      f.write(orders_csv(@orders))
    end
    File.open(File.join('/', 'tmp', 'SalorItems.tsv'),"w") do |f|
      f.write(items_csv(@items))
    end
    File.open(File.join('/', 'tmp', 'SalorDrawerTransactions.tsv'),"w") do |f|
      f.write(drawer_transactions_csv(@drawer_transactions))
    end
    File.open(File.join('/', 'tmp', 'SalorHistories.tsv'),"w") do |f|
      f.write(history_csv(@histories))
    end
    File.open(File.join('/', 'tmp', 'SalorReceipts.tsv'),"w") do |f|
      @receipts.each do |r|
        f.write("\n---\n#{r.created_at}\n#{r.ip}\n#{r.employee.username if r.employee}\n---\n\n")
        f.write r.content
      end
    end
    Dir.chdir('/tmp')
    `zip salor-retail.zip SalorOrders.tsv SalorItems.tsv SalorHistories.tsv SalorReceipts.tsv SalorDrawerTransactions.tsv`
  end
  
  def history_csv(histories)
   cols = [:created_at,:ip, :action_taken, :model_type,:model_id, :owner_type,:owner_id, :sensitivity,:url] 
   lines = []
   lines << cols.join("\t")
   histories.each do |h|
    line = []
    cols.each do |col|
      line << h.send(col.to_sym)
    end
    if not h.changes_made.empty? then
      begin
        changes = JSON.parse(h.changes_made)
        changes.each do |k,v|
          line << "#{h.model_type}[#{k}]"
          line << v[0].to_s.gsub("\n","<CR>")
          line << v[1].to_s.gsub("\n","<CR>")
        end
      rescue
        line << "Failed to parse JSON #{$!.inspect}"
      end
    end
    lines << line.join("\t")
   end
   return lines.join("\n")
  end
  def drawer_transactions_csv(drawer_transactions)
    cols = [:id, :drawer_id, :amount, :drop, :payout, :created_at, :updated_at, :notes, :is_refund, :tag, :drawer_amount, :cash_register_id, :order_item_id]
    cols.unshift(:class)
    lines = []
    lines << cols.join("\t")
    drawer_transactions.each do |drawer_transaction|
      line = []
      cols.each do |col|
        line << drawer_transaction.send(col.to_sym)
      end
      lines << line.join("\t")
    end
    return lines.join("\n")
  end
  def items_csv(items)
    cols = [:id,:class,:active,:hidden,:sku,:name,:behavior,:created_at,:updated_at,:quantity,:sales_metric,:base_price,:purchase_price,:buyback_price,:default_buyback,:tax_profile_amount,:packaging_unit,:child_id,:track_expiry,:expires_on,:shipper_id,:shipper_sku,:min_quantity, :is_part, :part_id,:part_quantity, :calculate_part_price,:coupon_type,:coupon_applies, :activated, :amount_remaining, :category_id,:location_id,:vendor_id]
    lines = []
    lines << cols.join("\t")
    items.each do |item|
      line = []
      cols.each do |col|
        line << item.send(col.to_sym)
      end
      lines << line.join("\t")
    end
    return lines.join("\n")
  end
  def orders_csv(orders)
    # FIXME add in payment methods
    cols = [:id,:class,:hidden,:created_at,:updated_at,:employee_id,:rebate,:rebate_type,:discount_amount,:buy_order,:drawer_id,:subtotal,:tax,:total,:front_end_change,:vendor_id,:cash_register_id, :customer_id, :lc_points, :lc_discount_amount,:tag]
    oi_cols = [:id,:class,:order_id,:hidden,:created_at,:updated_at,:item_id,:sku,:behavior,:quantity,:price,:tax,:total,:coupon_applied,:coupon_amount,:discount_applied, :discount_amount,:rebate,:is_buyback,:tax_profile_amount,:amount_remaining,:refunded,:refund_payment_method,:action_applied]
    pm_cols = [:order_id, "name", "internal_type", "amount", "created_at", "updated_at"]
    pm_cols.unshift(:class)
    pm_cols.unshift(:id)
    lines = []
    orders.each do |order|
      lines << "#" + cols.join("\t")
      line = []
      cols.each do |col|
        line << order.send(col.to_sym)
      end
      lines << line.join("\t")
      lines << "#" + oi_cols.join("\t")
      order.order_items.each do |oi|
        line = []
        oi_cols.each do |ocol|
          line << oi.send(ocol.to_sym)
        end
        lines << line.join("\t")
      end
      lines << "#" + pm_cols.join("\t")
      order.payment_methods.each do |pm|
        line = []
        pm_cols.each do |pcol|
          line << pm.send(pcol.to_sym)
        end
        lines << line.join("\t")
      end
    end
    return lines.join("\n")
  end
end
