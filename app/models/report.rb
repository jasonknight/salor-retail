# ------------------- Salor Point of Sale ----------------------- 
# An innovative multi-user, multi-store application for managing
# small to medium sized retail stores.
# Copyright (C) 2011-2012  Jason Martin <jason@jolierouge.net>
# Visit us on the web at http://salorpos.com
# 
# This program is commercial software (All provided plugins, source code, 
# compiled bytecode and configuration files, hereby referred to as the software). 
# You may not in any way modify the software, nor use any part of it in a 
# derivative work.
# 
# You are hereby granted the permission to use this software only on the system 
# (the particular hardware configuration including monitor, server, and all hardware 
# peripherals, hereby referred to as the system) which it was installed upon by a duly 
# appointed representative of Salor, or on the system whose ownership was lawfully 
# transferred to you by a legal owner (a person, company, or legal entity who is licensed 
# to own this system and software as per this license). 
#
# You are hereby granted the permission to interface with this software and
# interact with the user data (Contents of the Database) contained in this software.
#
# You are hereby granted permission to export the user data contained in this software,
# and use that data any way that you see fit.
#
# You are hereby granted the right to resell this software only when all of these conditions are met:
#   1. You have not modified the source code, or compiled code in any way, nor induced, encouraged, 
#      or compensated a third party to modify the source code, or compiled code.
#   2. You have purchased this system from a legal owner.
#   3. You are selling the hardware system and peripherals along with the software. They may not be sold
#      separately under any circumstances.
#   4. You have not copied the software, and maintain no sourcecode backups or copies.
#   5. You did not install, or induce, encourage, or compensate a third party not permitted to install 
#      this software on the device being sold.
#   6. You have obtained written permission from Salor to transfer ownership of the software and system.
#
# YOU MAY NOT, UNDER ANY CIRCUMSTANCES
#   1. Transmit any part of the software via any telecommunications medium to another system.
#   2. Transmit any part of the software via a hardware peripheral, such as, but not limited to,
#      USB Pendrive, or external storage medium, Bluetooth, or SSD device.
#   3. Provide the software, in whole, or in part, to any thrid party unless you are exercising your
#      rights to resell a lawfully purchased system as detailed above.
#
# All other rights are reserved, and may be granted only with direct written permission from Salor. By using
# this software, you agree to adhere to the rights, terms, and stipulations as detailed above in this license, 
# and you further agree to seek to clarify any right not directly spelled out herein. Any right, not directly 
# covered by this license is assumed to be reserved by Salor, and you agree to contact an official Salor repre-
# sentative to clarify any rights that you infer from this license or believe you will need for the proper 
# functioning of your business.
class Report
  def dump_all(from,to,device)
    tfrom = from.strftime("%Y%m%d")
    tto = to.strftime("%Y%m%d")
    from = from.strftime("%Y-%m-%d 01:00:00")
    to = to.strftime("%Y-%m-%d 23:59:59")
    @orders = Order.where(["(created_at BETWEEN ? AND ?) OR (updated_at BETWEEN ? AND ?)",from,to,from,to]).order("created_at DESC")
    @items = Item.where(["(created_at BETWEEN ? AND ?) OR (updated_at BETWEEN ? AND ?)",from,to,from,to]).order("created_at DESC")
    @histories = History.where(["(created_at BETWEEN ? AND ?) OR (updated_at BETWEEN ? AND ?)",from,to,from,to]).order("created_at DESC")
    @drawer_transactions = DrawerTransaction.where(["(created_at BETWEEN ? AND ?) OR (updated_at BETWEEN ? AND ?)",from,to,from,to]).order("created_at DESC")
    @receipts = Receipt.where(["(created_at BETWEEN ? AND ?) OR (updated_at BETWEEN ? AND ?)",from,to,from,to]).order("created_at DESC")

    File.open("#{device}/SalorOrders#{tfrom}-#{tto}.tsv","w") do |f|
      f.write(orders_csv(@orders))
    end
    File.open("#{device}/SalorItems#{tfrom}-#{tto}.tsv","w") do |f|
      f.write(items_csv(@items))
    end
    File.open("#{device}/SalorDrawerTransactions#{tfrom}-#{tto}.tsv","w") do |f|
      f.write(drawer_transactions_csv(@drawer_transactions))
    end
    File.open("#{device}/SalorHistory#{tfrom}-#{tto}.tsv","w") do |f|
      f.write(history_csv(@histories))
    end
    File.open("#{device}/SalorReceipts#{tfrom}-#{tto}.txt","w") do |f|
      @receipts.each do |r|
        f.write("\n---\n#{r.created_at}\n#{r.ip}\n#{r.employee.username}\n---\n\n")
        f.write r.content
      end
    end
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
    cols = DrawerTransaction.content_columns
    cols.map! {|c| c.name}
    cols.unshift(:class)
    cols.unshift(:id)
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
    pm_cols = PaymentMethod.content_columns
    pm_cols.map! {|c| c.name}
    pm_cols.unshift(:order_id)
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
