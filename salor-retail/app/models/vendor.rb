# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class Vendor < ActiveRecord::Base

  include SalorScope

  
  belongs_to :company
  
  has_many :item_types
  has_many :loyalty_cards
  has_many :payment_methods
  has_many :payment_method_items
  has_many :drawer_transactions
  has_many :drawers
  has_many :sale_types
  has_many :countries
  has_many :transaction_tags
  has_many :order_items
  has_many :actions
  has_many :buttons
  
  has_many :cash_registers
  has_one  :salor_configuration
  has_many :orders
  has_many :categories
  has_many :items
  has_many :locations
  has_many :users
  has_many :current_registers
  has_many :customers
  has_many :broken_items
  has_many :shipments_received, :as => :receiver
  has_many :returns_sent, :as => :shipper
  has_many :shipments
  has_many :vendor_printers
  has_many :shippers
  has_many :discounts
  has_many :stock_locations
  has_many :shipment_items, :through => :shipments
  has_many :tax_profiles
  has_many :shipment_types
  has_many :invoice_blurbs
  has_many :invoice_notes
  has_many :item_stocks
  has_many :receipts
  

  serialize :unused_order_numbers
  serialize :unused_quote_numbers
  
  def gs1_regexp
    parts = self.gs1_format.split(",")
    return Regexp.new "\\d{#{ parts[0] }}(\\d{#{ parts[1] }})(\\d{#{ parts[2] }})"
  end
  
  def payment_methods_types_list
    types = []
    self.payment_methods.visible.where(:change => nil).each do |p|
      types << [p.name, p.id]
    end
    return types
  end
  
  def payment_methods_as_objects
    types = {}
    self.payment_methods.visible.where('`change` IS NULL OR `change` = FALSE').each do |p|
      types[p.id] = { :name => p.name, :id => p.id, :cash => p.cash }
    end
    return types
  end
  
  def get_current_discounts
    self.discounts.where(["start_date <= ? and end_date >= ?",Time.now,Time.now])
  end

  def receipt_logo_header=(data)
    if data.nil?
      write_attribute :receipt_logo_header, nil
    else
      write_attribute :receipt_logo_header, Escper::Img.new(data.read, :blob).to_s
    end
  end

  def receipt_logo_footer=(data)
    if data.nil?
      write_attribute :receipt_logo_footer, nil
    else
      write_attribute :receipt_logo_footer, Escper::Img.new(data.read, :blob).to_s 
    end
  end

  def logo=(data)
    write_attribute :logo_image_content_type, data.content_type.chomp
    write_attribute :logo_image, data.read
  end

  def logo_invoice=(data)
    write_attribute :logo_invoice_image_content_type, data.content_type.chomp
    write_attribute :logo_invoice_image, data.read
  end

  
  def get_unique_model_number(model_name_singular)
    model_name_plural = model_name_singular + 's'
    return 0 if not self.send("use_#{model_name_singular}_numbers")
    if not self.send("unused_#{model_name_singular}_numbers").empty?
      # reuse order numbers if present'
      nr = self.send("unused_#{model_name_singular}_numbers").first
      self.send("unused_#{model_name_singular}_numbers").delete(nr)
      self.save
    elsif not self.send("largest_#{model_name_singular}_number").zero?
      # increment largest model number'
      nr = self.send("largest_#{model_name_singular}_number") + 1
      self.update_attribute "largest_#{model_name_singular}_number", nr
    else
      # find Order with largest nr attribute from database. this should happen only once, when having a new database
      if model_name_plural == 'quotes' then
        last_model = self.send('orders').visible.where('qnr is not NULL OR qnr <> 0').last
        nr = last_model ? last_model.qnr + 1 : 1
      else
        last_model = self.send(model_name_plural).visible.where('nr is not NULL OR nr <> 0').last
        nr = last_model ? last_model.nr + 1 : 1
      end
      self.update_attribute "largest_#{model_name_singular}_number", nr
    end
    return nr
  end
  
  def self.reset_for_tests
    t = Time.now - 24.hours
    Drawer.update_all :amount => 0
    Order.where(:created_at => t...(Time.now)).delete_all
    OrderItem.where(:created_at => t...(Time.now)).delete_all
    DrawerTransaction.where(:created_at => t...(Time.now)).delete_all
    PaymentMethod.where(:created_at => t...(Time.now)).delete_all
    Category.update_all :cash_made => 0
    Category.update_all :quantity_sold => 0
    Location.update_all :cash_made => 0
    Location.update_all :quantity_sold => 0
    SalorConfiguration.update_all :calculate_tax => false
    CashRegister.update_all :require_password => false
  end
  
  def self.debug_setup
    i = 110
    text = ""
    User.all.each do |e|
      e.update_attribute :password, i.to_s
      text += "#{e.id} #{e.username}: #{i}\n"
      i += 1
    end
    puts text
  end
  
  def self.debug_user_info
    text = ""
    User.all.each do |e|
      text += e.debug_info
    end
    puts text
  end
  
  def net_prices
    ['cc', 'us', 'ca'].include? self.country
  end
  
  def self.debug_order_info(fname,limit=1000)
    File.open(fname,"w+") do |f|
      Order.order("created_at desc").limit(limit).each do |order|
        pms = {}
        order.payment_methods.each do |pm|
          pms[pm.internal_type] ||= { :count => 0, :name => "", :values => []}
          pms[pm.internal_type][:count] += 1
          if pms[pm.internal_type][:count] > 1 then
            f.write "!Problem: more than one of the same pm on an order\n"
          end
          pms[pm.internal_type][:name] = pm.name
          pms[pm.internal_type][:values] << pm.amount
        end
        f.write "Order: #{order.id} with NR #{order.nr} or QNR #{order.qnr}\n"
        f.write "\t Date: #{order.created_at}\n"
        f.write "\t Owner: #{order.user.last_name}, #{order.user.first_name} as #{order.user.username}\n"
        f.write "\t Order Items: #{order.order_items.visible.count} visible of #{order.order_items.count}\n"
        f.write "\t Payment Methods: #{pms.to_json}\n"
      end
    end
    return "Done"
  end
  
  def get_end_of_day_report(from=nil, to=nil, drawer=nil)
    from ||= Time.now.beginning_of_day
    to ||= Time.now.end_of_day
    drawer ||= self.users.visible.collect{|u| u.get_drawer.id }
    
    orders = self.orders.visible.where(:paid => true, :created_at => from..to, :drawer_id => drawer)
    orders_count = orders.count
    
    # revenue
    revenue = {}
    if self.net_prices
      revenue[:gro] = (orders.sum(:total) + orders.sum(:tax_amount)).round(2)
      revenue[:net] = orders.sum(:total).round(2)
    else
      revenue[:gro] = orders.sum(:total).round(2)
      revenue[:net] = (orders.sum(:total) - orders.sum(:tax_amount)).round(2)
    end
    
    # DrawerTransactions
    transactions = []
    if drawer
      drawer_transactions = self.drawer_transactions.visible.where(
        :drawer_id => drawer,
        :created_at => from.beginning_of_day..to.end_of_day
      ).where(:complete_order => nil, :refund => nil)
    else
      drawer_transactions = self.drawer_transactions.where(
        :created_at => from.beginning_of_day..to.end_of_day
      ).where(:complete_order => nil, :refund => nil)
    end
    drawer_transactions.each do |dt|
      transactions << {:tag => dt.tag, :notes => dt.notes, :amount => dt.amount.round(2), :time => dt.created_at}
    end
    transactions_sum = drawer_transactions.sum(:amount).round(2)

    # Categories
    categories = {:pos => {}, :neg => {}}
    categories_sum = {:pos => {:gro => 0.0, :net => 0.0}, :neg => {:gro => 0.0, :net => 0.0}}
    used_categories = self.order_items.visible.where(:created_at => from..to, :drawer_id => drawer).select("DISTINCT category_id")
    used_categories.each do |r|
      cat = self.categories.find_by_id(r.category_id)
      label = cat.name
      
      pos_subtotal = self.order_items.visible.where(:created_at => from..to, :drawer_id => drawer, :category_id => r.category_id).where("subtotal > 0").sum(:subtotal).round(2)
      pos_tax = self.order_items.visible.where(:created_at => from..to, :drawer_id => drawer, :category_id => r.category_id).where("subtotal > 0").sum(:tax_amount).round(2)
      neg_subtotal = self.order_items.visible.where(:created_at => from..to, :drawer_id => drawer, :category_id => r.category_id).where("subtotal < 0").sum(:subtotal).round(2)
      neg_tax = self.order_items.visible.where(:created_at => from..to, :drawer_id => drawer, :category_id => r.category_id).where("subtotal < 0").sum(:tax_amount).round(2)
      
      unless pos_subtotal.zero?
        categories[:pos][label] = {}
        categories[:pos][label][:tax] = pos_tax
        if self.net_prices
          categories[:pos][label][:gro] = pos_subtotal + pos_tax
          categories[:pos][label][:net] = pos_subtotal
        else
          categories[:pos][label][:gro] = pos_subtotal
          categories[:pos][label][:net] = pos_subtotal - pos_tax
        end
        categories_sum[:pos][:net] += categories[:pos][label][:net]
        categories_sum[:pos][:gro] += categories[:pos][label][:gro]
      end
      
      unless neg_subtotal.zero?
        categories[:neg][label] = {}
        categories[:neg][label][:tax] = neg_tax
        if self.net_prices
          categories[:neg][label][:gro] = neg_subtotal + neg_tax
          categories[:neg][label][:net] = neg_subtotal
        else
          categories[:neg][label][:gro] = neg_subtotal
          categories[:neg][label][:net] = neg_subtotal - neg_tax
        end
        categories_sum[:neg][:net] += categories[:neg][label][:net]
        categories_sum[:neg][:gro] += categories[:neg][label][:gro]
      end
    end
      
          
      
    
    # Taxes
    taxes = {:pos => {}, :neg => {}}
    used_tax_amounts = self.order_items.visible.where(:created_at => from..to, :drawer_id => drawer).select("DISTINCT tax")
    used_tax_amounts.each do |r|
      taxes[:pos][r.tax] = {}
      taxes[:neg][r.tax] = {}
      
      pos_subtotal = self.order_items.visible.where(:created_at => from..to, :drawer_id => drawer, :tax => r.tax).where("subtotal > 0").sum(:subtotal).round(2)
      pos_tax = self.order_items.visible.where(:created_at => from..to, :drawer_id => drawer, :tax => r.tax).where("subtotal > 0").sum(:tax_amount).round(2)
      neg_subtotal = self.order_items.visible.where(:created_at => from..to, :drawer_id => drawer, :tax => r.tax).where("subtotal < 0").sum(:subtotal).round(2)
      neg_tax = self.order_items.visible.where(:created_at => from..to, :drawer_id => drawer, :tax => r.tax).where("subtotal < 0").sum(:tax_amount).round(2)
      
      taxes[:pos][r.tax][:tax] = pos_tax
      taxes[:neg][r.tax][:tax] = neg_tax
      if self.net_prices
        taxes[:pos][r.tax][:gro] = pos_subtotal + pos_tax
        taxes[:neg][r.tax][:gro] = neg_subtotal + neg_tax
        taxes[:pos][r.tax][:net] = pos_subtotal
        taxes[:neg][r.tax][:net] = neg_subtotal

      else
        taxes[:pos][r.tax][:gro] = pos_subtotal
        taxes[:neg][r.tax][:gro] = neg_subtotal
        taxes[:pos][r.tax][:net] = pos_subtotal - pos_tax
        taxes[:neg][r.tax][:net] = neg_subtotal - neg_tax
      end
    end
    
    # PaymentMethods
    paymentmethods = {:pos => {}, :neg => {}}
    used_payment_methods = self.payment_method_items.visible.where(:created_at => from..to, :drawer_id => drawer, :refund => nil).select("DISTINCT payment_method_id")
    used_payment_methods.each do |r|
      pm = self.payment_methods.find_by_id(r.payment_method_id)
      raise "#{ r.inspect }" if pm.nil?
      next if pm.change
      
      if pm.cash
        # cash needs special treatment, since actual cash amount = cash given - change given
        change_pm = self.payment_methods.visible.find_by_change(true)
        
        cash_positive = self.payment_method_items.visible.where(:created_at => from..to, :drawer_id => drawer, :payment_method_id => pm, :refund => nil).where("amount > 0").sum(:amount).round(2)
        change_positive = self.payment_method_items.visible.where(:created_at => from..to, :drawer_id => drawer, :payment_method_id => change_pm, :refund => nil).sum(:amount).round(2)
        
        cash_negative = self.payment_method_items.visible.where(:created_at => from..to, :drawer_id => drawer, :payment_method_id => pm, :refund => nil).where("amount < 0").sum(:amount).round(2)
        
        paymentmethods[:pos][pm.name] = cash_positive + change_positive
        paymentmethods[:neg][pm.name] = cash_negative
        
      else
        paymentmethods[:pos][pm.name] = self.payment_method_items.visible.where(:created_at => from..to, :drawer_id => drawer, :payment_method_id => pm, :refund => nil).where("amount > 0").sum(:amount).round(2)
        paymentmethods[:neg][pm.name] = self.payment_method_items.visible.where(:created_at => from..to, :drawer_id => drawer, :payment_method_id => pm, :refund => nil).where("amount < 0").sum(:amount).round(2)
      end
    end
    
    # Refunds
    refunds = {}
    used_refund_payment_methods = self.payment_method_items.visible.where(:created_at => from..to, :drawer_id => drawer, :refund => true).select("DISTINCT payment_method_id")
    used_refund_payment_methods.each do |r|
      pm = self.payment_methods.find_by_id(r.payment_method_id)
      
      refunds[pm.name] = self.payment_method_items.visible.where(:created_at => from..to, :drawer_id => drawer, :payment_method_id => pm, :refund => true).sum(:amount).round(2)
    end

    calculated_drawer_amount = self.drawer_transactions.where(:created_at => from.beginning_of_day..to.end_of_day, :drawer_id => drawer).sum(:amount).round(2)
    
    report = Hash.new
    report['categories'] = categories
    report['taxes'] = taxes
    report['paymentmethods'] = paymentmethods
    report['refunds'] = refunds
    report['revenue'] = revenue
    report['transactions'] = transactions
    report['transactions_sum'] = transactions_sum
    report['calculated_drawer_amount'] = calculated_drawer_amount
    report['orders_count'] = orders_count
    report['categories_sum'] = categories_sum
    report[:date_from] = I18n.l(from, :format => :just_day)
    report[:date_to] = I18n.l(to, :format => :just_day)
    report[:unit] = I18n.t('number.currency.format.friendly_unit')
    if drawer.class == Drawer
      report[:drawer_amount] = drawer.amount
      report[:username] = "#{ drawer.user.first_name } #{ drawer.user.last_name } (#{ drawer.user.username })"
    else
      report[:drawer_amount] = 0
      report[:username] = ''
    end
    return report
  end
  
  def print_eod_report(from=nil, to=nil, drawer=nil, cash_register)
    text = self.escpos_eod_report(from, to, drawer)
    printerconfig = {
      :id => 0,
      :name => cash_register.name,
      :path => cash_register.thermal_printer,
      :copie => 1,
      :codepage => 0,
      :baudrate => 9600
    }
    print_engine = Escper::Printer.new('local', printerconfig)
    print_engine.open
    print_engine.print(0, text)
    print_engine.close
    
    return text
  end
  
  def escpos_eod_report(from=nil, to=nil, drawer=nil)
    report = get_end_of_day_report(from, to, drawer)

    categories = report['categories']
    taxes = report['taxes']
    paymentmethods = report['paymentmethods']
    refunds  =  report['refunds']
    revenue =   report['revenue']
    transactions   = report['transactions']
    transactions_sum   = report['transactions_sum']
    calculated_drawer_amount =   report['calculated_drawer_amount']
    orders_count = report['orders_count']
    categories_sum = report['categories_sum']
    date_from = report[:date_from]
    date_to = report[:date_to]
    unit = report[:unit]
    drawer_amount = report[:drawer_amount]
    username = report[:username]
    
    line_format = "%24.24s  %7.2f %7.2f\n"
    line_format2 = "%28.28s %s %8.2f\n"
    line_format3 = "%-25s %7s %7s\n"
    transactions_format = " %5.5s  %9.9s %9.9s  %s %8.2f\n"

    vendorname =
    "\e@"     +  # Initialize Printer
    "\e!\x38" +  # doube tall, double wide, bold
    self.name + "\n"

    
    header = ''
    header +=
    "\ea\x00" +  # align left
    "\e!\x01" +  # Font B
    "#{ date_from } -> #{ date_to }" +
    "\n" +
    username +
    "\n==========================================\n\n"


    
    groups = {}
    [[:pos,'.sales'], [:neg,'.payments']].each do |i|
      type = i[0]
      groups[type] = ""
      
      group_header =
          "\e!\x18" +
          I18n.t("printr.eod_report#{ i[1] }") +
          "\e!\x00" +
          "\n"
      
      category_header =
          line_format3 % [
            I18n.t('orders.report_day.sums_by_category'),
            I18n.t('orders.report_day.net'),
            I18n.t('orders.report_day.gross')
          ]
      
      category_lines = "\n"
      categories[i[0]].to_a.each do |c|
        category_lines +=
            line_format % [
              c[0].empty? ? t('printr.eod_report.no_category') : c[0],
              c[1][:net],
              c[1][:gro]
            ]
      end
      
      taxes_header = I18n.t('orders.report_day.sums_by_tax_profile')
      taxes_lines = "\n"
      taxes[i[0]].to_a.each do |t|
        taxes_lines +=
            line_format % [
              t[0],
              t[1][:net],
              t[1][:gro]
            ]
      end

      payments_header = I18n.t('orders.report_day.sums_by_payment_methods')
      payments_lines = "\n"
      paymentmethods[i[0]].to_a.each do |p|
        payments_lines +=
            line_format2 % [
              p[0],
              report[:unit],
              p[1]
            ]
      end
      
      subtotal = "\n"
      subtotal +=
          line_format2 % [
            I18n.t('printr.eod_report.payment_method_total'),
            report[:unit],
            categories_sum[i[0]][:gro]
          ]
      
      groups[type] +=
          group_header +
          category_header +
          category_lines +
          "\n" +
          taxes_header +
          taxes_lines +
          "\n" +
          payments_header +
          payments_lines +
          subtotal
    end

  
    refund_header = "\n"
    refund_lines = "\n"
    if refunds.any?
      refund_header +=
          "\e!\x18" +
          I18n.t('printr.eod_report.refunds') +
          "\e!\x00"
    
    
      refunds.each do |k,v|
        refund_lines +=
            line_format2 % [
              k,
              report[:unit],
              v
            ]
      end
    end
    
    revenue_header = "\n"
    revenue_header +=
        "\e!\x18" +
        I18n.t('printr.eod_report.revenue') + 
        "\e!\x00"
    
    revenue_lines = "\n"
    revenue_lines +=
        line_format2 % [
          I18n.t('printr.eod_report.revenue_total'),
          report[:unit],
          revenue[:gro]
        ]
    
    
    transactions_header = "\n"
    if from == to.beginning_of_day
      transactions_header +=
          "\e!\x18" + 
          I18n.t('activerecord.models.drawer_transaction.other') +
          "\e!\x00" +
          "\n--------------"
    end
    
    transactions_lines = "\n"
    if from == to.beginning_of_day
      transactions.to_a.each do |d|
        transactions_lines +=
            transactions_format % [
              I18n.l(d[:time], :format => :just_time),
              d[:tag],
              d[:notes],
              report[:unit],
              d[:amount]
            ]
      end
    end
    
    transactions_footer = "\n"
    transactions_footer +=
        line_format2 % [
          I18n.t('printr.eod_report.transaction_total'),
          report[:unit],
          transactions_sum
        ]
    
    calculated_drawer_amount_line = "\n\n"
    calculated_drawer_amount_line +=
        line_format2 % [
          I18n.t("printr.eod_report.calculated_drawer_amount"),
          report[:unit],
          calculated_drawer_amount
        ]
    
    unless calculated_drawer_amount.round(2).zero?
      calculated_drawer_amount +=
          "\n******************************************\n" +
          I18n.t('printr.eod_report.warning_drawer_amount_not_zero') +
          "\n******************************************\n"
    end


    bigspace = "\n\n\n\n\n\n"
    cut = "\x1D\x56\x00"
    
    output = ""
    output +=
        vendorname +
        header +
        groups[:pos] +
        groups[:neg] +
        refund_header +
        refund_lines +
        transactions_header +
        transactions_lines +
        transactions_footer +
        calculated_drawer_amount_line +
        bigspace +
        cut
    
    return output

  end
end
