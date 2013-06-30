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
  has_many :drawer_transactions
  has_many :drawers
  has_many :sale_types
  has_many :countries
  has_many :tender_methods
  has_many :transaction_tags
  has_many :order_items
  
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
  has_many :paylife_structs
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

  def salor_configuration_attributes=(hash)
    if self.salor_configuration.nil? then
      self.salor_configuration = SalorConfiguration.new hash
      self.salor_configuration.save
      return
    end
    self.salor_configuration.update_attributes(hash)
  end
  
  def payment_methods_types_list
    types = []
    pmx = I18n.t("system.payment_external_types").split(',')
    pmi = I18n.t("system.payment_internal_types").split(',')
    tms = self.tender_methods.visible
    i = 0
    pmi.each do |p|
      types << [pmx[i],p]
      i  = i + 1
    end
    tms.each do |tm|
      types << [tm.name,tm.internal_type]
    end
    return types
  end
  
  def payment_methods_as_objects
    types = []
    pmx = I18n.t("system.payment_external_types").split(',')
    pmi = I18n.t("system.payment_internal_types").split(',')
    tms = self.tender_methods.visible
    i = 0
    pmi.each do |p|
      types << {:name => pmx[i],:internal_type => p} if p != 'Change'
      i  = i + 1
    end
    tms.each do |tm|
      types << {:name => tm.name,:internal_type => tm.internal_type}
    end
    return types
  end
  
  def get_current_discounts
    self.discounts.where(["start_date <= ? and end_date >= ?",Time.now,Time.now])
  end
  
  def set_vendor_printers=(printers)
    self.connection.execute("delete from vendor_printers where vendor_id = '#{self.id}'")
    ps = []
    printers.each do |printer|
      p = VendorPrinter.new(printer)
      p.vendor_id = self.id
      p.save
      ps << p.id
    end
    self.vendor_printer_ids = ps
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
  
  def get_end_of_day_report(from, to, user)
    categories = self.categories.visible
    taxes = self.tax_profiles.visible
    if user
      orders = self.orders.visible.where(
        :drawer_id => user.get_drawer.id,
        :created_at => from.beginning_of_day..to.end_of_day,
        :paid => true,
        :unpaid_invoice => nil, #migration!
        :is_quote => nil #migration!
      ).order("created_at ASC")
      drawertransactions = self.drawer_transactions.visible.where(
        :drawer_id => user.get_drawer.id,
        :created_at => from.beginning_of_day..to.end_of_day
      ).where("tag != 'CompleteOrder'")
    else
      orders = self.orders.visible.where(
        :created_at => from.beginning_of_day..to.end_of_day,
        :paid => true,
        :unpaid_invoice => nil, #migration!
        :is_quote => nil #migration!
      ).order("created_at ASC")
      drawertransactions = self.drawer_transactions.where(
        :created_at => from.beginning_of_day..to.end_of_day
      ).where("tag != 'CompleteOrder'")
    end
    
    regular_payment_methods = self.payment_methods_types_list.collect{|pm| pm[1].to_s }

    categories = {:pos => {}, :neg => {}}
    taxes = {:pos => {}, :neg => {}}
    paymentmethods = {:pos => {}, :neg => {}, :refund => {}}
    refunds = { :cash => { :gro => 0, :net => 0 }, :noncash => { :gro => 0, :net => 0 }}

    orders.each do |o|
      o.payment_methods.each do |p|
        ptype = p.internal_type.to_sym
        if not regular_payment_methods.include?(p.internal_type)
          if not paymentmethods[:refund].has_key?(ptype)
            paymentmethods[:refund][ptype] = p.amount
          else
            paymentmethods[:refund][ptype] += p.amount
          end
        #elsif p.internal_type == 'InCash'
          #ignore those. cash will be calculated as difference between category sum and other normal payment methods
        else
          if p.amount > 0
            if not paymentmethods[:pos].has_key?(ptype)
              paymentmethods[:pos][ptype] = p.amount
            else
              paymentmethods[:pos][ptype] += p.amount
            end
          end
          if p.amount < 0
            if not paymentmethods[:neg].has_key?(ptype)
              paymentmethods[:neg][ptype] = p.amount
            else
              paymentmethods[:neg][ptype] += p.amount
            end
          end
        end
      end # end o.payment_methods

      next if o.is_proforma == true # for an explanation see issue #1399
      
      o.order_items.visible.each do |oi|
        next if oi.sku == 'DMYACONTO'
        catname = oi.category ? oi.category.name : ''
        taxname = oi.tax_profile.name if oi.tax_profile
        taxname = OrderItem.human_attribute_name(:tax_free) if oi.order.tax_free
        item_price = case oi.behavior
          when 'normal' then oi.price
          when 'gift_card' then oi.activated ? - oi.total : oi.total
          when 'coupon' then oi.order_item ? - oi.order_item.coupon_amount / oi.quantity  : 0
        end
        item_price = oi.price * ( 1 - oi.rebate / 100.0 ) if oi.rebate
        item_price = - oi.price if o.buy_order
        item_total = oi.total_is_locked ? oi.total : item_price * oi.quantity
        item_total = item_total * ( 1 - o.rebate / 100.0 ) if o.rebate_type == 'percent' # spread order percent rebate equally
        item_total -= o.rebate / o.order_items.visible.count if o.rebate_type == 'fixed' # spread order fixed rebate equally
        item_total -= o.lc_discount_amount / o.order_items.visible.count  # spread order lc discount amount 
        item_total -= oi.discount_amount if oi.discount_applied
        
        if o.tax_free == true
          gro = item_total
          net = item_total
        else
          fact = oi.tax_profile_amount / 100
          # How much of the sum goes to the store after taxes
          if not self.calculate_tax then
            net = item_total / (1.00 + fact)
            gro = item_total
          else
            # I.E. The net total is the item total because the tax is outside that price.
            net = item_total
            gro = item_total * (1 + fact)
          end
        end
        if item_total > 0.0
          if not categories[:pos].has_key?(catname)
            categories[:pos].merge! catname => { :gro => gro, :net => net }
          else
            categories[:pos][catname][:gro] += gro
            categories[:pos][catname][:net] += net
          end
          if not taxes[:pos].has_key?(taxname)
            taxes[:pos].merge! taxname => { :gro => gro, :net => net }
          else
            taxes[:pos][taxname][:gro] += gro
            taxes[:pos][taxname][:net] += net
          end
        elsif item_total < 0.0
          if not categories[:neg].has_key?(catname)
            categories[:neg].merge! catname => { :gro => gro, :net => net }
          else
            categories[:neg][catname][:gro] += gro
            categories[:neg][catname][:net] += net
          end
          if not taxes[:neg].has_key?(taxname)
            taxes[:neg].merge! taxname => { :gro => gro, :net => net }
          else
            taxes[:neg][taxname][:gro] += gro
            taxes[:neg][taxname][:net] += net
          end
        end
        if oi.refunded
          if oi.refund_payment_method == 'InCash'
            refunds[:cash][:gro] -= gro
            refunds[:cash][:net] -= net
          else
            refunds[:noncash][:gro] -= gro
            refunds[:noncash][:net] -= net
          end
        end
      end
    end

    categories_sum = { :pos => { :gro => 0, :net => 0 }, :neg => { :gro => 0, :net => 0 }}

    categories_sum[:pos][:gro] = categories[:pos].to_a.collect{|x| x[1][:gro]}.sum
    categories_sum[:pos][:net] = categories[:pos].to_a.collect{|x| x[1][:net]}.sum
    #XXXpaymentmethods[:pos]['InCash'] = categories_sum[:pos][:gro] - paymentmethods[:pos].to_a.collect{|x| x[1]}.sum

    categories_sum[:neg][:gro] = categories[:neg].to_a.collect{|x| x[1][:gro]}.sum
    categories_sum[:neg][:net] = categories[:neg].to_a.collect{|x| x[1][:net]}.sum
    #XXXpaymentmethods[:neg]['InCash'] = categories_sum[:neg][:gro] - paymentmethods[:neg].to_a.collect{|x| x[1]}.sum

    transactions = Hash.new
    transactions_sum = { :drop => 0, :payout => 0, :total => 0}
    drawertransactions.each do |d|
      transactions[d.id] = { :drop => d.drop, :is_refund => d.is_refund, :time => d.created_at, :notes => d.notes, :tag => d.tag.to_s + "(#{d.id})", :amount => d.amount }
      if d.drop and not d.is_refund
        transactions_sum[:drop] += d.amount
      elsif d.payout and not d.is_refund
        transactions_sum[:payout] -= d.amount
      end
        transactions_sum[:total] = transactions_sum[:drop] + transactions_sum[:payout]
    end

    revenue = Hash.new
    revenue[:gro] = categories[:pos].to_a.map{|x| x[1][:gro]}.sum + categories[:neg].to_a.map{|x| x[1][:gro]}.sum + refunds[:cash][:gro] + refunds[:noncash][:gro]
    revenue[:net] = categories[:pos].to_a.map{|x| x[1][:net]}.sum + categories[:neg].to_a.map{|x| x[1][:net]}.sum + refunds[:cash][:net] + refunds[:noncash][:net]
    
    paymentmethods[:pos][:InCash] ||= 0
    paymentmethods[:neg][:InCash] ||= 0
    paymentmethods[:neg][:Change] ||= 0
    # This is not the best way to handle change, change is a drawer transaction, not a payment method.
    paymentmethods[:pos][:InCash] += paymentmethods[:neg][:Change]
    paymentmethods[:neg].delete(:Change)
    
    
    # Mathematically, this should work, but actually it does not because of the limitations of ruby itself, this leads to some obscure floating point overflow.
    # if you perform the calculations with a calculator it will give the correct answer, but in SOME instances this will produce an astronomically large negative
    # floating point number that will display as -0.0 on the report, but will actually be something like -9.879837419238798e-13
    #calculated_drawer_amount = transactions_sum[:drop] + transactions_sum[:payout] + refunds[:cash][:gro] + paymentmethods[:pos][:InCash] + paymentmethods[:neg][:InCash]
    
    # This should be the valid way to do it, because all movements of money in the system should be done as drawer transactions.
    calculated_drawer_amount = DrawerTransaction.where({:created_at => from.beginning_of_day..to.end_of_day, :drop => true }).sum(:amount) - DrawerTransaction.where({:created_at => from.beginning_of_day..to.end_of_day, :payout => true }).sum(:amount)
    report = Hash.new
    report['categories'] = categories
    report['taxes'] = taxes
    report['paymentmethods'] = paymentmethods
    report['regular_payment_methods'] = regular_payment_methods
    report['refunds'] = refunds
    report['revenue'] = revenue
    report['transactions'] = transactions
    report['transactions_sum'] = transactions_sum
    report['calculated_drawer_amount'] = calculated_drawer_amount
    report['orders_count'] = orders.count
    report['categories_sum'] = categories_sum
    report[:date_from] = I18n.l(from, :format => :just_day)
    report[:date_to] = I18n.l(to, :format => :just_day)
    report[:unit] = I18n.t('number.currency.format.friendly_unit')
    if user
      report[:drawer_amount] = user.get_drawer.amount
      report[:username] = "#{ user.first_name } #{ user.last_name } (#{ user.username })"
    else
      report[:drawer_amount] = 0
      report[:username] = ''
    end
    return report
  end
end
