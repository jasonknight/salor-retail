# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class Vendor < ActiveRecord::Base

  include SalorScope
  include ImageMethods
  
  belongs_to :company
  has_and_belongs_to_many :users
  
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
  has_many :roles
  has_many :buttons
  has_many :images, :as => :imageable
  has_many :plugins
  
  has_many :cash_registers
  has_many :orders
  has_many :categories
  has_many :items
  has_many :locations
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
  has_many :shipment_items
  has_many :tax_profiles
  has_many :shipment_types
  has_many :invoice_blurbs
  has_many :invoice_notes
  has_many :item_stocks
  has_many :receipts
  has_many :user_logins
  

  serialize :unused_order_numbers
  serialize :unused_quote_numbers
  
  validates_presence_of :name
  validates_presence_of :currency
  validates_uniqueness_of :identifier, :scope => :company_id
  after_create :set_hash_id
  before_save :set_currency
  
  accepts_nested_attributes_for :images, :allow_destroy => true, :reject_if => :all_blank
  #README
  # 1. The rails way would lead to many duplications
  # 2. The rails way would require us to reorganize all the translation files
  # 3. The rails way in this case is admittedly limited, by their own docs, and they suggest you implement your own
  # 4. Therefore, don't remove this code.
  def self.human_attribute_name(attrib)
    begin
      trans = I18n.t("activerecord.attributes.#{attrib.downcase}", :raise => true) 
      return trans
    rescue
      SalorBase.log_action self.class, "trans error raised for activerecord.attributes.#{attrib} with locale: #{I18n.locale}"
      return super
    end
  end
  def region
    SalorRetail::Application::COUNTRIES_REGIONS[self.country] 
  end
  
  def set_currency
    currencystring = I18n.t('number.currency.format.friendly_unit', :locale => self.region)
    self.currency = currencystring
  end
  
  def logo_image
    return self.image('logo') if Image.where(:imageable_type => 'Vendor', :imageable_id => self.id, :image_type => 'logo').any?
    "/assets/blank.png"
  end
  
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
    drawer ||= self.users.visible.collect{|u| u.get_drawer.id }.uniq
    
    orders = self.orders.visible.where(
      :paid => true,
      :paid_at => from..to,
      :drawer_id => drawer,
      :is_proforma => nil,
    )
    count_orders = orders.count
    
    count_order_items = self.order_items.visible.where(
      :paid => true,
      :paid_at => from..to,
      :drawer_id => drawer,
      :is_proforma => nil,
    ).count

   # README: All amounts called "negative" below are buyback only. All other negatively priced OrderItems which are not buyback are either of Type gift_card or aconto. Those will be listed separately on the day report, so that accountants can enter them more easily into their own software.

    # Categories.
    categories = {
      :pos => {},
      :neg => {}
    }
    categories_sum = {
      :pos => {
               :gro => Money.new(0, self.currency),
               :net => Money.new(0, self.currency)
              },
      :neg => {
               :gro => Money.new(0, self.currency),
               :net => Money.new(0, self.currency)
              }
    }
    used_categories = self.order_items.visible.where(
      :paid => true,
      :paid_at => from..to,
      :drawer_id => drawer,
      :is_proforma => nil,
      :behavior => 'normal'
    ).select("DISTINCT category_id")
    used_categories.each do |r|
      cat = self.categories.find_by_id(r.category_id)
      label = cat ? cat.name : "-"
      
      pos_total_cents = self.order_items.visible.where(
        :paid => true,
        :paid_at => from..to,
        :drawer_id => drawer,
        :is_proforma => nil,
        :category_id => r.category_id,
        :behavior => 'normal'
      ).where("total_cents > 0").sum(:total_cents)
      pos_total = Money.new(pos_total_cents, self.currency)
      
      pos_tax_cents = self.order_items.visible.where(
        :paid => true,
        :paid_at => from..to,
        :drawer_id => drawer,
        :is_proforma => nil,
        :category_id => r.category_id,
        :behavior => 'normal'
      ).where("total_cents > 0").sum(:tax_amount_cents)
      pos_tax = Money.new(pos_tax_cents, self.currency)
      
      neg_total_cents = self.order_items.visible.where(
        :paid => true,
        :paid_at => from..to,
        :drawer_id => drawer,
        :is_proforma => nil,
        :category_id => r.category_id,
        :is_buyback => true,
        :behavior => 'normal'
      ).where("total_cents < 0").sum(:total_cents)
      neg_total = Money.new(neg_total_cents, self.currency)
      
      neg_tax_cents = self.order_items.visible.where(
        :paid => true,
        :paid_at => from..to,
        :drawer_id => drawer,
        :is_proforma => nil,
        :category_id => r.category_id,
        :is_buyback => true,
        :behavior => 'normal'
      ).where("total_cents < 0").sum(:tax_amount_cents)
      neg_tax = Money.new(neg_tax_cents, self.currency)
      
      unless pos_total.zero?
        categories[:pos][label] = {}
        categories[:pos][label][:tax] = pos_tax
        categories[:pos][label][:gro] = pos_total
        categories[:pos][label][:net] = pos_total - pos_tax
        categories_sum[:pos][:net] += categories[:pos][label][:net]
        categories_sum[:pos][:gro] += categories[:pos][label][:gro]
      end
      
      unless neg_total.zero?
        categories[:neg][label] = {}
        categories[:neg][label][:tax] = neg_tax
        categories[:neg][label][:gro] = neg_total
        categories[:neg][label][:net] = neg_total - neg_tax
        categories_sum[:neg][:net] += categories[:neg][label][:net]
        categories_sum[:neg][:gro] += categories[:neg][label][:gro]
      end
    end
      
          
      
    
    # Taxes
    taxes = {
      :pos => {},
      :neg => {}
    }
    used_tax_amounts = self.order_items.visible.where(
      :paid => true,
      :paid_at => from..to,
      :drawer_id => drawer,
      :is_proforma => nil,
      :behavior => 'normal',
    ).select("DISTINCT tax")
    used_tax_amounts.each do |r|
      taxes[:pos][r.tax] = {}
      taxes[:neg][r.tax] = {}
      
      pos_total_cents = self.order_items.visible.where(
        :paid => true,
        :paid_at => from..to,
        :drawer_id => drawer,
        :is_proforma => nil,
        :tax => r.tax,
        :behavior => 'normal'
      ).where("total_cents > 0").sum(:total_cents)
      pos_total = Money.new(pos_total_cents, self.currency)
      
      pos_tax_cents = self.order_items.visible.where(
        :paid => true,
        :paid_at => from..to,
        :drawer_id => drawer,
        :is_proforma => nil,
        :tax => r.tax,
        :behavior => 'normal'
      ).where("total_cents > 0").sum(:tax_amount_cents)
      pos_tax = Money.new(pos_tax_cents, self.currency)
      
      neg_total_cents = self.order_items.visible.where(
        :paid => true,
        :paid_at => from..to,
        :drawer_id => drawer,
        :is_proforma => nil,
        :tax => r.tax,
        :is_buyback => true,
        :behavior => 'normal'
      ).where("total_cents < 0").sum(:total_cents)
      neg_total = Money.new(neg_total_cents, self.currency)
      
      neg_tax_cents = self.order_items.visible.where(
        :paid => true,
        :paid_at => from..to,
        :drawer_id => drawer,
        :is_proforma => nil,
        :tax => r.tax,
        :is_buyback => true,
        :behavior => 'normal'
      ).where("total_cents < 0").sum(:tax_amount_cents)
      neg_tax = Money.new(neg_tax_cents, self.currency)
      
      taxes[:pos][r.tax][:tax] = pos_tax
      taxes[:neg][r.tax][:tax] = neg_tax
      taxes[:pos][r.tax][:gro] = pos_total
      taxes[:neg][r.tax][:gro] = neg_total
      taxes[:pos][r.tax][:net] = pos_total - pos_tax
      taxes[:neg][r.tax][:net] = neg_total - neg_tax
    end
    
    # PaymentMethods
    paymentmethods = {
      :pos => {},
      :neg => {}
    }
    used_payment_methods = self.payment_method_items.visible.where(
      :paid => true,
      :paid_at => from..to,
      :drawer_id => drawer,
      :is_proforma => nil,
      :refund => nil
    ).select("DISTINCT payment_method_id")
    used_payment_methods.each do |r|
      pm = self.payment_methods.find_by_id(r.payment_method_id)
      raise "#{ r.inspect }" if pm.nil?
      next if pm.change
      
      if pm.cash
        # cash needs special treatment, since actual cash amount = cash given - change given
        change_pm = self.payment_methods.visible.find_by_change(true)
        
        cash_positive_cents = self.payment_method_items.visible.where(
          :paid => true,
          :paid_at => from..to,
          :drawer_id => drawer,
          :is_proforma => nil,
          :payment_method_id => pm,
          :refund => nil
        ).where("amount_cents > 0").sum(:amount_cents)
        cash_positive = Money.new(cash_positive_cents, self.currency)
        
        change_positive_cents = self.payment_method_items.visible.where(
          :paid => true,
          :paid_at => from..to,
          :drawer_id => drawer,
          :is_proforma => nil,
          :payment_method_id => change_pm,
          :refund => nil
        ).sum(:amount_cents)
        change_positive = Money.new(change_positive_cents, self.currency)
        
        cash_negative_cents = self.payment_method_items.visible.where(
          :paid => true,
          :paid_at => from..to,
          :drawer_id => drawer,
          :is_proforma => nil,
          :payment_method_id => pm,
          :refund => nil,
        ).where("amount_cents < 0").sum(:amount_cents)
        cash_negative = Money.new(cash_negative_cents, self.currency)
        
        paymentmethods[:pos][pm.name] = cash_positive + change_positive
        paymentmethods[:neg][pm.name] = cash_negative
        
      else
        pmi_pos_cents = self.payment_method_items.visible.where(
          :paid => true,
          :paid_at => from..to,
          :drawer_id => drawer,
          :is_proforma => nil,
          :payment_method_id => pm,
          :refund => nil
        ).where("amount_cents > 0").sum(:amount_cents)
        paymentmethods[:pos][pm.name] = Money.new(pmi_pos_cents, self.currency)
        
        pmi_neg_cents = self.payment_method_items.visible.where(
          :paid => true,
          :paid_at => from..to,
          :drawer_id => drawer,
          :is_proforma => nil,
          :payment_method_id => pm,
          :refund => nil,
        ).where("amount_cents < 0").sum(:amount_cents)
        paymentmethods[:neg][pm.name] = Money.new(pmi_neg_cents, self.currency)
      end
    end
    
    # Refunds. we query those according to paymentMethoditems. TODO: output order nr. on report page.
    refunds = {}
    used_refund_payment_methods = self.payment_method_items.visible.where(
      :paid => true,
      :paid_at => from..to,
      :drawer_id => drawer,
      :is_proforma => nil,
      :refund => true
    ).select("DISTINCT payment_method_id")
    used_refund_payment_methods.each do |r|
      pm = self.payment_methods.find_by_id(r.payment_method_id)
      
      refund_cents = self.payment_method_items.visible.where(
        :paid => true,
        :paid_at => from..to,
        :drawer_id => drawer,
        :is_proforma => nil,
        :payment_method_id => pm,
        :refund => true).sum(:amount_cents)
      refunds[pm.name] = Money.new(refund_cents, self.currency)
    end

    
    # Aconto payments
    # for proforma Orders only payment method items are effective, not the OrderItems. reason: the report would include OrderItems of both proforma and derived Order, but in reality there were only sold once. The derived Order however will be fully effective in regards to OrderItems.
    proforma_orders = self.orders.visible.where(
      :paid => true,
      :paid_at => from..to,
      :drawer_id => drawer,
      :is_proforma => true,
    )
    proforma_paymentmethods = {}
    used_proforma_payment_methods = self.payment_method_items.visible.where(
      :paid => true,
      :paid_at => from..to,
      :drawer_id => drawer,
      :is_proforma => true,
      :refund => nil
    ).select("DISTINCT payment_method_id")
    used_proforma_payment_methods.each do |r|
      pm = self.payment_methods.find_by_id(r.payment_method_id)
      raise "#{ r.inspect }" if pm.nil?
      ppmi_cents = self.payment_method_items.visible.where(
        :paid => true,
        :paid_at => from..to,
        :drawer_id => drawer,
        :is_proforma => true,
        :payment_method_id => pm,
        :refund => nil
      ).sum(:amount_cents)
      proforma_paymentmethods[pm.name] = Money.new(ppmi_cents, self.currency)
    end
    
    
    # revenue is the  Total of everything for this day based on OrderItems. it is significant for accountants. reveue is synonymous with the term turnover. it does not include aconto OrderItems since those Orders are fully effective for the revenue (unlike the proforma Orders which are not effective regarding revenut, but effective regarding payment methods)
    revenue = {}
    gro_cents = self.order_items.visible.where(
      :paid => true,
      :paid_at => from..to,
      :drawer_id => drawer,
      :is_proforma => nil,
      :behavior => 'normal'
    ).sum(:total_cents)
    revenue[:gro] = Money.new(gro_cents, self.currency)
    tax_cents = self.order_items.visible.where(
      :paid => true,
      :paid_at => from..to,
      :drawer_id => drawer,
      :behavior => 'normal'
    ).sum(:tax_amount_cents)
    revenue[:net] = revenue[:gro] - Money.new(tax_cents, self.currency)
    
    
    # DrawerTransactions. this generates a list of manually made drawer transactions
    transactions = []
    drawer_transactions = self.drawer_transactions.visible.where(
      :created_at => from..to,
      :complete_order => nil,
      :drawer_id => drawer,
      :refund => nil
    )

    drawer_transactions.each do |dt|
      transactions << {
        :tag => dt.tag,
        :notes => dt.notes,
        :amount => dt.amount,
        :time => dt.created_at
      }
    end
    transactions_sum = Money.new(drawer_transactions.sum(:amount_cents), self.currency)
    
    # Total of everything for this day based on drawer transactions. this also includes proforma payments, since proforma Orders are effective re. payment methods. this is Cash only. This must match the current Drawer.amount at all times during a working day.
    calc_drawer_cents = self.drawer_transactions.where(
      :created_at => from..to,
      :drawer_id => drawer
    ).sum(:amount_cents)
    calculated_drawer_amount = Money.new(calc_drawer_cents, self.currency)
    
    
    # Gift Cards
    gift_cards_sold = self.order_items.visible.where(
      :completed_at => from..to,
      :behavior => 'gift_card',
      :drawer_id => drawer,
      :refunded => nil,
      :activated => nil
    )
    gift_card_sales_total = Money.new(gift_cards_sold.sum(:total_cents), self.currency)
    
    gift_cards_redeemed = self.order_items.visible.where(
      :completed_at => from..to,
      :behavior => 'gift_card',
      :drawer_id => drawer,
      :refunded => nil,
      :activated => true
    )
    gift_card_redeem_total = - Money.new(gift_cards_redeemed.sum(:total_cents), self.currency)
    

    
    report = Hash.new
    report['categories'] = categories
    report['taxes'] = taxes
    report['paymentmethods'] = paymentmethods
    report['proforma_paymentmethods'] = proforma_paymentmethods
    report['gift_cards_redeemed'] = gift_cards_redeemed
    report['gift_card_redeem_total'] = gift_card_redeem_total
    report['gift_cards_sold'] = gift_cards_sold
    report['gift_card_sales_total'] = gift_card_sales_total
    report['refunds'] = refunds
    report['revenue'] = revenue
    report['transactions'] = transactions
    report['transactions_sum'] = transactions_sum
    report['calculated_drawer_amount'] = calculated_drawer_amount
    report['count_orders'] = count_orders
    report['count_order_items'] = count_order_items
    report['categories_sum'] = categories_sum
    report[:date_from] = I18n.l(from, :format => :just_day)
    report[:date_to] = I18n.l(to, :format => :just_day)
    report[:unit] = I18n.t('number.currency.format.friendly_unit', :locale => self.region)
    if drawer.class == Drawer
      report[:drawer_amount] = drawer.amount
      report[:username] = "#{ drawer.user.first_name } #{ drawer.user.last_name } (#{ drawer.user.username })"
    else
      report[:drawer_amount] = 0
      report[:username] = ''
    end
    return report
  end
  
  def get_statistics(from, to)
    orders = self.orders.visible.where(:paid => true, :completed_at => from..to)

    reports = {
        :items => {},
        :categories => {},
        :locations => {}
    }
    
    # TODO: Replace this loop by self.mymodel.where().sum(:blah) SQL queries for high speed. removed the UI icon in the meantime
#     orders.each do |o|
#       o.order_items.visible.each do |oi|
#         next if oi.item.nil?
#         key = oi.item.name + " (#{oi.price})"
#         cat_key = oi.get_category_name
#         loc_key = oi.get_location_name
#         
#         reports[:items][key] ||= {:sku => '', :quantity_sold => 0.0, :cash_made => 0.0 }
#         reports[:items][key][:quantity_sold] += oi.quantity
#         reports[:items][key][:cash_made] += oi.total
#         reports[:items][key][:sku] = oi.sku
#         
#         reports[:categories][cat_key] ||= { :quantity_sold => 0.0, :cash_made => 0.0 }
#         
#         reports[:categories][cat_key][:quantity_sold] += oi.quantity
#         reports[:categories][cat_key][:cash_made] += oi.total
#         
#         reports[:locations][loc_key] ||= { :quantity_sold => 0.0, :cash_made => 0.0 }
#         
#         reports[:locations][loc_key][:quantity_sold] += oi.quantity
#         reports[:locations][loc_key][:cash_made] += oi.total
#       end
#     end
# 
#     reports[:categories_by_cash_made] = reports[:categories].sort_by { |k,v| v[:cash_made] }
#     reports[:categories_by_quantity_sold] = reports[:categories].sort_by { |k,v| v[:quantity_sold] }
#     reports[:locations_by_cash_made] = reports[:locations].sort_by { |k,v| v[:cash_made] }
#     reports[:locations_by_quantity_sold] = reports[:locations].sort_by { |k,v| v[:quantity_sold] }
#     reports[:items].sort_by { |k,v| v[:quantity_sold] }
    
    return reports
  end
  
  def print_eod_report(from=nil, to=nil, drawer=nil, cash_register)
    return if self.company.mode != 'local'
    text = self.escpos_eod_report(from, to, drawer)
    
    vp = Escper::VendorPrinter.new({})
    vp.id = 0
    vp.name = cash_register.name
    vp.path = cash_register.thermal_printer
    vp.copies = 1
    vp.codepage = 0
    vp.baudrate = 9600

    print_engine = Escper::Printer.new('local', vp)
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
    count_orders = report['count_orders']
    count_order_items = report['count_order_items']
    categories_sum = report['categories_sum']
    date_from = report[:date_from]
    date_to = report[:date_to]
    unit = report[:unit]
    drawer_amount = report[:drawer_amount]
    username = report[:username]
    
    line_format  = "%19.19s %10.2f %10.2f\n"
    line_format2 = "%19.19s %3.3s %17.2f\n"
    line_format3 = "%-19s %10s %10s\n"
    transactions_format = "%-14s %8.8s %4.4s %s %8.2f\n"

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
    
    
    generalstatistics = ''
    generalstatistics +=
        "#{ I18n.l(DateTime.now) }\n\n" +
        "#{ I18n.t 'vendors.report_day.count_orders' }: #{ count_orders }\n" +
        "#{ I18n.t 'vendors.report_day.count_order_items' }: #{ count_order_items }\n\n"


    
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
            I18n.t('vendors.report_day.sums_by_category'),
            I18n.t('vendors.report_day.net'),
            I18n.t('vendors.report_day.gross')
          ]
      
      category_lines = "\n"
      categories[i[0]].to_a.each do |c|
        category_lines +=
            line_format % [
              c[0].blank? ? I18n.t('printr.eod_report.no_category') : c[0],
              c[1][:net],
              c[1][:gro]
            ]
      end
      
      taxes_header = I18n.t('vendors.report_day.sums_by_tax_profile')
      taxes_lines = "\n"
      taxes[i[0]].to_a.each do |t|
        taxes_lines +=
            line_format % [
              t[0],
              t[1][:net],
              t[1][:gro]
            ]
      end

      payments_header = I18n.t('vendors.report_day.sums_by_payment_methods')
      payments_lines = "\n"
      paymentmethods[i[0]].to_a.each do |p|
        payments_lines +=
            line_format2 % [
              p[0],
              '',
              p[1]
            ]
      end
      
      total = "\n"
      total +=
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
          total
    end

  
    refund_header = "\n"
    refund_lines = "\n"
    if refunds.any?
      refund_header +=
          "\e!\x18" +
          I18n.t('vendors.report_day.refunds') +
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
    transactions_header +=
        "\e!\x18" + 
        I18n.t('activerecord.models.drawer_transaction.other') +
        "\e!\x00" +
        "\n--------------"
    
    transactions_lines = "\n"
    transactions.to_a.each do |d|
      transactions_lines +=
          transactions_format % [
            d[:time].strftime('%d. %b %H:%M'),
            d[:tag],
            d[:notes],
            report[:unit],
            d[:amount]
          ]
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
    
    unless calculated_drawer_amount.zero?
      calculated_drawer_amount_line +=
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
        generalstatistics +
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
  
  
  # params[:type] = 'sticker|label'
  # params[:style] = '{{ any string }}'
  def print_labels(model, params, cash_register)
    params[:style] ||= 'default'

    if model == 'item'
      if params[:id]
        @items = self.items.visible.where(:id => params[:id])
      elsif params[:skus]
        # text has been entered on the items#selection scren
        match = /(ORDER)(.*)/.match(params[:skus].split(",").first)
        if match and match[1] == 'ORDER'
          # print labels from all OrderItems of that Order
          order_id = match[2].to_i
          @order_items = self.orders.find_by_id(order_id).order_items.visible
          @items = []
        else
          # print only the entered SKUs
          @order_items = []
          skus = params[:skus].split(",")
          @items = self.items.visible.where(:sku => skus)
        end
      end
    elsif model == 'customer'
      @customers = self.customers.visible.where(:id => params[:id])
    end
    
    @currency = I18n.t('number.currency.format.friendly_unit', :locale => self.region)
    template = File.read("#{Rails.root}/app/views/printr/#{ model }_#{params[:type]}_#{params[:style]}.prnt.erb")
    erb = ERB.new(template, 0, '>')
    text = erb.result(binding)
      
    if params[:download] == 'true'
      return Escper::Asciifier.new.process(text)
    elsif cash_register.salor_printer
      return Escper::Asciifier.new.process(text)
    elsif self.company.mode == 'local'
      if params[:type] == 'sticker'
        printer_path = cash_register.sticker_printer
      else
        printer_path = cash_register.thermal_printer
      end
      vp = Escper::VendorPrinter.new({})
      vp.id = 0
      vp.name = cash_register.name
      vp.path = printer_path
      vp.copies = 1
      vp.codepage = 0
      vp.baudrate = 9600
      
      print_engine = Escper::Printer.new('local', vp)
      print_engine.open
      print_engine.print(0, text)
      print_engine.close
    end
  end
  
  def set_hash_id
    self.hash_id = "#{ self.identifier }#{ generate_random_string[0..20] }"
    Vendor.connection.execute("UPDATE vendors set hash_id = '#{self.hash_id}'")
  end
  
  def json_tax_profiles
    hash = {}
    self.tax_profiles.visible.each do |tp|
      hash[tp.id] = {
        :id => tp.id,
        :color => tp.color,
        :name => tp.name,
        :value => tp.value
      }
    end
    return hash.to_json
  end
  
  # self.check_range : will run tests for today
  # self.check_range("2013-01-10") will run tests for specified day
  # self.check_range("2013-01-10", "2013-01-12") will run tests between specified days
  def check_range(from=nil, to=nil, blacklist = [:orderItemTaxRoundingNet, :orderItemTaxRounding])
    if from
      from = Date.parse(from).beginning_of_day
    else
      from = Time.now.beginning_of_day
    end
    
    if to
      to = Date.parse(to).end_of_day
    elsif from.nil?
      to = Time.now.end_of_day
    else
      to = from.end_of_day
    end
    
    tests = []
    
    drawers = self.drawers
    drawers.each do |d|
      result = d.check_range(from, to)
      tests << result unless result == []
    end
      
    orders = self.orders.visible.paid.where(:created_at => from..to)
    orders.each do |o|
      result = o.check
      tests << result unless result == []
    end
    
    filtered_tests = []
    tests.each do |t|
      filtered_tests << t unless blacklist.include? t[3]
    end
    
    return tests
  end
  
  private
  
  def generate_random_string
    collection = [('a'..'z'),('A'..'Z'),('0'..'9')].map{|i| i.to_a}.flatten
    (0...128).map{ collection[rand(collection.length)] }.join
  end
end
