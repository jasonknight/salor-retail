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
  
  has_many :inventory_reports
  has_many :item_types
  has_many :loyalty_cards
  has_many :payment_methods
  has_many :payment_method_items
  has_many :drawer_transactions
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
  validates_presence_of :company_id
  
  validates_uniqueness_of :name, :scope => :hidden
  validates_uniqueness_of :identifier, :scope => :hidden
  validate :identifer_present_and_ascii
  
  before_save :set_hash_id
  
  accepts_nested_attributes_for :images, :allow_destroy => true, :reject_if => :all_blank
  
  #README
  # 1. The rails way would lead to many duplications
  # 2. The rails way would require us to reorganize all the translation files
  # 3. The rails way in this case is admittedly limited, by their own docs, and they suggest you implement your own
  # 4. Therefore, don't remove this code.
  def self.human_attribute_name(attrib, options={})
    begin
      trans = I18n.t("activerecord.attributes.#{attrib.downcase}", :raise => true) 
      return trans
    rescue
      SalorBase.log_action self.class, "trans error raised for activerecord.attributes.#{attrib} with locale: #{I18n.locale}"
      return super
    end
  end
  
  def run_diagnostics
    return Item.run_diagnostics
  end
  
  def identifer_present_and_ascii
    if self.identifier.blank?
      errors.add(:identifier, I18n.t('activerecord.errors.messages.empty'))
      return
    end
    
    if self.identifier.length < 4
      errors.add(:identifier, I18n.t('activerecord.errors.messages.too_short', :count => 4))
      return
    end
    
    match = /[a-zA-Z0-9_-]*/.match(self.identifier)[0]
    if match != self.identifier
      errors.add(:identifier, I18n.t('activerecord.errors.messages.must_be_ascii'))
    end
  end
  
  def region
    SalorRetail::Application::COUNTRIES_REGIONS[self.country] 
  end
  
  def logo_image
    return self.image('logo') if Image.where(
      :imageable_type => 'Vendor',
      :imageable_id => self.id,
      :image_type => 'logo'
    ).any?
    return "/assets/blank.png"
  end
  
  def gs1_regexp
    parts = self.gs1_format.split(",")
    return Regexp.new "\\d{#{ parts[0] }}(\\d{#{ parts[1] }})(\\d{#{ parts[2] }})"
  end
  
  # this is currently only used on orders/print to change unpaid orders. using cash/change/unpaid/quote there doesn't make sense, so we exclude it.
  def payment_methods_types_list
    types = []
    self.payment_methods.visible.where(:change => nil, :unpaid => nil, :quote => nil).order("name ASC").each do |p|
      types << [p.name, p.id]
    end
    return types
  end
  
  def payment_methods_as_objects
    types = {}
    self.payment_methods.visible.where(:change => nil).order("name ASC").each do |p|
      ## Javascript hashes are autosorted by key integer value, but not sorted when keys are strings with a letter. We need to keep the order, so we export the keys as strings with letters.
      types["pmid#{p.id}"] = {
        :name => p.name,
        :id => p.id,
        :cash => p.cash
      }
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
  
  def location_stock_location_list
    ret = []
    self.locations.visible.order(:name).each do |l|
      ret << [l.name, 'Location:' + l.id.to_s]
    end
    self.stock_locations.visible.all.each do |sl|
      ret << [sl.name, 'StockLocation:' + sl.id.to_s]
    end
    return ret
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

  def net_prices
    ['cc', 'us', 'ca'].include? self.country
  end
  
  def get_end_of_day_report(from=nil, to=nil, drawer=nil)
    from ||= Time.now.beginning_of_day
    to ||= Time.now.end_of_day
    drawer ||= self.users.visible.collect{|u| u.get_drawer.id }.uniq
    
    orders = self.orders.visible.where(
      :completed_at => from..to,
      :drawer_id => drawer,
      :is_proforma => nil,
      :is_quote => nil,
    )
    count_orders = orders.count
    
    count_order_items = self.order_items.visible.where(
      :completed_at => from..to,
      :drawer_id => drawer,
      :is_proforma => nil,
      :is_quote => nil,
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
      :completed_at => from..to,
      :drawer_id => drawer,
      :is_proforma => nil,
      :is_quote => nil,
      :behavior => 'normal',
    ).select("DISTINCT category_id")

#     used_categories = self.categories.visible.order(:name)
#     used_categories << nil
    used_categories.each do |r|
      cat = self.categories.find_by_id(r.category_id)
      label = cat ? cat.name : "-"
      
      pos_total_cents = self.order_items.visible.where(
        :completed_at => from..to,
        :drawer_id => drawer,
        :is_proforma => nil,
        :is_quote => nil,
        :category_id => cat,
        :behavior => 'normal'
      ).where("is_buyback = FALSE OR is_buyback IS NULL").sum(:total_cents)
      pos_total = Money.new(pos_total_cents, self.currency)
      
      pos_tax_cents = self.order_items.visible.where(
        :completed_at => from..to,
        :drawer_id => drawer,
        :is_proforma => nil,
        :is_quote => nil,
        :category_id => cat,
        :behavior => 'normal'
      ).where("is_buyback = FALSE OR is_buyback IS NULL").sum(:tax_amount_cents)
      pos_tax = Money.new(pos_tax_cents, self.currency)
      
      neg_total_cents = self.order_items.visible.where(
        :completed_at => from..to,
        :drawer_id => drawer,
        :is_proforma => nil,
        :is_quote => nil,
        :category_id => cat,
        :behavior => 'normal'
      ).where("is_buyback = TRUE").sum(:total_cents)
      neg_total = Money.new(neg_total_cents, self.currency)
      
      neg_tax_cents = self.order_items.visible.where(
        :completed_at => from..to,
        :drawer_id => drawer,
        :is_proforma => nil,
        :is_quote => nil,
        :category_id => cat,
        :behavior => 'normal'
      ).where("is_buyback = TRUE").sum(:tax_amount_cents)
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
      :completed_at => from..to,
      :drawer_id => drawer,
      :is_proforma => nil,
      :is_quote => nil,
      :behavior => 'normal',
    ).select("DISTINCT tax")
    #used_taxes = self.tax_profiles.visible
    used_tax_amounts.each do |r|
      taxes[:pos][r.tax] = {}
      taxes[:neg][r.tax] = {}
      
      pos_total_cents = self.order_items.visible.where(
        :completed_at => from..to,
        :drawer_id => drawer,
        :is_proforma => nil,
        :is_quote => nil,
        :tax => r.tax,
        :behavior => 'normal'
      ).where("is_buyback = FALSE OR is_buyback IS NULL").sum(:total_cents)
      pos_total = Money.new(pos_total_cents, self.currency)
      
      pos_tax_cents = self.order_items.visible.where(
        :completed_at => from..to,
        :drawer_id => drawer,
        :is_proforma => nil,
        :is_quote => nil,
        :tax => r.tax,
        :behavior => 'normal'
      ).where("is_buyback = FALSE OR is_buyback IS NULL").sum(:tax_amount_cents)
      pos_tax = Money.new(pos_tax_cents, self.currency)
      
      neg_total_cents = self.order_items.visible.where(
        :completed_at => from..to,
        :drawer_id => drawer,
        :is_proforma => nil,
        :is_quote => nil,
        :tax => r.tax,
        :behavior => 'normal'
      ).where("is_buyback = TRUE").sum(:total_cents)
      neg_total = Money.new(neg_total_cents, self.currency)
      
      neg_tax_cents = self.order_items.visible.where(
        :completed_at => from..to,
        :drawer_id => drawer,
        :is_proforma => nil,
        :is_quote => nil,
        :tax => r.tax,
        :behavior => 'normal'
      ).where("is_buyback = TRUE").sum(:tax_amount_cents)
      neg_tax = Money.new(neg_tax_cents, self.currency)
      
      taxes[:pos][r.tax][:tax] = pos_tax
      taxes[:neg][r.tax][:tax] = neg_tax
      taxes[:pos][r.tax][:gro] = pos_total
      taxes[:neg][r.tax][:gro] = neg_total
      taxes[:pos][r.tax][:net] = pos_total - pos_tax
      taxes[:neg][r.tax][:net] = neg_total - neg_tax
    end
    
    # PaymentMethods
    paymentmethods = {}
    paymentmethods_total_cents = self.payment_method_items.visible.where(
      :completed_at => from..to,
      :drawer_id => drawer,
      :is_proforma => nil,
      :is_quote => nil,
    ).sum(:amount_cents)
    paymentmethods_total = Money.new(paymentmethods_total_cents, self.currency)
    
    used_payment_methods = self.payment_method_items.visible.where(
      :completed_at => from..to,
      :drawer_id => drawer,
      :is_proforma => nil,
      :is_quote => nil,
    ).select("DISTINCT payment_method_id")

    used_payment_methods.each do |r|
      pm = self.payment_methods.find_by_id(r.payment_method_id)
      
      next if pm.change # ignore change. we only consider cash (separately), and all others pms
      
      if pm.cash
        # cash needs special treatment, since actual cash amount = cash given - change given
        change_pm = self.payment_methods.visible.find_by_change(true)
        
        cash_cents = self.payment_method_items.visible.where(
          :completed_at => from..to,
          :drawer_id => drawer,
          :is_proforma => nil,
          :is_quote => nil,
          :payment_method_id => pm
        ).sum(:amount_cents)
        cash = Money.new(cash_cents, self.currency)
        
        change_cents = self.payment_method_items.visible.where(
          :completed_at => from..to,
          :drawer_id => drawer,
          :is_proforma => nil,
          :is_quote => nil,
          :payment_method_id => change_pm
        ).sum(:amount_cents)
        change = Money.new(change_cents, self.currency)
        
        paymentmethods[pm.id] = {:name => pm.name, :amount => cash + change}
        
      else
        pmi_cents = self.payment_method_items.visible.where(
          :completed_at => from..to,
          :drawer_id => drawer,
          :is_proforma => nil,
          :is_quote => nil,
          :payment_method_id => pm
        ).sum(:amount_cents)
        
        paymentmethods[pm.id] = {:name => pm.name, :amount => Money.new(pmi_cents, self.currency)} unless pmi_cents.zero?
      end
    end

    
    # Aconto payments
    # for proforma Orders only payment method items are effective, not the OrderItems. reason: the report would include OrderItems of both proforma and derived Order, but in reality there were only sold once. The derived Order however will be fully effective in regards to OrderItems.
    proforma_pmis = {}
    ppmis = self.payment_method_items.visible.where(
      :completed_at => from..to,
      :drawer_id => drawer,
      :is_proforma => true,
      :is_quote => nil,
    )
    ppmis.each do |ppmi|
      proforma_pmis[ppmi.id] = {
        :name => ppmi.payment_method.name,
        :amount => ppmi.amount
      }
    end
    proforma_pmis_total = Money.new(ppmis.sum(:amount_cents), self.currency)
    
    aconto_order_items = {}
    aois = self.order_items.visible.where(
      :completed_at => from..to,
      :paid => true,
      :is_quote => nil,
      :drawer_id => drawer,
      :behavior => 'aconto'
    )
    aois.each do |oi|
      aconto_order_items[oi.id] = {
        :order_id => oi.order_id,
        :order_blurb => "#{ I18n.t('orders.print.invoice') } #{ oi.order.nr }",
        :amount => - oi.total
      }
    end
    aconto_total = - Money.new(aois.sum(:total_cents), self.currency)
    
    
    # Refunds
    refund_order_items = {}
    rois = self.order_items.visible.where(
      :completed_at => from..to,
      :paid => true,
      :is_quote => nil,
      :drawer_id => drawer,
      :refunded => true
    )
    rois.each do |oi|
      if oi.refund_payment_method_item
        pmi_blurb = oi.refund_payment_method_item.payment_method.name
        pmiid = oi.refund_payment_method_item_id
      else
        pmi_blurb = "Link to PaymentMethodItem lost"
        pmiid = 0
      end
      if oi.item
        blurb = oi.item.name
      else
        blurb = "Link to Item lost"
      end
      refund_order_items[oi.id] = {
        :order_id => oi.order_id,
        :blurb => blurb,
        :order_blurb => "#{ I18n.t('orders.print.invoice') } ##{ oi.order.nr }",
        :pmi_id => pmiid,
        :pmi_blurb => pmi_blurb
      }
    end
    
    
    # revenue is the  Total of everything for this day based on OrderItems. it is significant for accountants. reveue is synonymous with the term turnover. it does not include aconto OrderItems since those Orders are fully effective for the revenue (unlike the proforma Orders which are not effective regarding revenut, but effective regarding payment methods)
    revenue = {}
    gro_cents = self.order_items.visible.where(
      :completed_at => from..to,
      :drawer_id => drawer,
      :is_proforma => nil,
      :is_quote => nil,
      :behavior => 'normal'
    ).sum(:total_cents)
    revenue[:gro] = Money.new(gro_cents, self.currency)
    tax_cents = self.order_items.visible.where(
      :completed_at => from..to,
      :drawer_id => drawer,
      :is_quote => nil,
      :behavior => 'normal'
    ).sum(:tax_amount_cents)
    revenue[:net] = revenue[:gro] - Money.new(tax_cents, self.currency)
    
    
    # DrawerTransactions. this generates a list of manually made drawer transactions
    transactions = []
    drawer_transactions = self.drawer_transactions.visible.where(
      :created_at => from..to,
      :complete_order => nil,
      :drawer_id => drawer
    )

    drawer_transactions.each do |dt|
      transactions << {
        :tag => dt.tag.to_s,
        :notes => dt.notes.to_s,
        :amount => dt.amount,
        :time => dt.created_at
      }
    end
    transactions_sum = Money.new(drawer_transactions.sum(:amount_cents), self.currency)
    
    # Total of everything for this day based on drawer transactions. this also includes proforma payments, since proforma Orders are effective re. payment methods. this is Cash only. This must match the current Drawer.amount at all times during a working day.
    calc_drawer_cents = self.drawer_transactions.visible.where(
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
      :is_quote => nil,
      :activated => nil
    )
    gift_card_sales_total = Money.new(gift_cards_sold.sum(:total_cents), self.currency)
    
    
    gift_cards_redeemed = self.order_items.visible.where(
      :completed_at => from..to,
      :behavior => 'gift_card',
      :drawer_id => drawer,
      :refunded => nil,
      :is_quote => nil,
      :activated => true
    )
    gift_card_redeem_total = - Money.new(gift_cards_redeemed.sum(:total_cents), self.currency)
    

    report = Hash.new
    report['categories'] = categories
    report['taxes'] = taxes
    report['paymentmethods'] = paymentmethods
    report['paymentmethods_total'] = paymentmethods_total
    report['proforma_pmis'] = proforma_pmis
    report['proforma_pmis_total'] = proforma_pmis_total
    report['gift_cards_redeemed'] = gift_cards_redeemed
    report['gift_card_redeem_total'] = gift_card_redeem_total
    report['gift_cards_sold'] = gift_cards_sold
    report['gift_card_sales_total'] = gift_card_sales_total
    report['refund_order_items'] = refund_order_items
    report['aconto_order_items'] = aconto_order_items
    report['aconto_total'] = aconto_total
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
  
  # OrderItem.connection.execute("SELECT category_id, item_id, sku, ROUND(SUM(quantity), 2), SUM(total_cents) FROM order_items WHERE hidden IS NULL GROUP BY category_id, item_id ").to_a
  
  def get_sales_statistics(from, to, category_id=nil)
    category_id = nil if category_id == 0
    
    if category_id
      category_query = "AND category_id = #{ category_id }"
    else
      category_query = ""
    end
    
    order_item_quantities_by_category = OrderItem.connection.execute("SELECT category_id, item_id, sku, SUM(quantity), SUM(total_cents) FROM order_items WHERE vendor_id = #{ self.id } AND hidden IS NULL AND completed_at BETWEEN '#{ from.strftime("%Y-%m-%d %H:%M:%S") }' AND '#{ to.strftime("%Y-%m-%d %H:%M:%S") }'  #{ category_query } GROUP BY category_id, item_id").to_a
    reports = {
      :order_item_quantities_by_category => order_item_quantities_by_category,
    }
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

    print_engine = Escper::Printer.new(self.company.mode, vp, File.join(SalorRetail::Application::SR_DEBIAN_SITEID, self.hash_id))
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
    paymentmethods_total = report['paymentmethods_total']
    proforma_pmis = report['proforma_pmis']
    proforma_pmis_total = report['proforma_pmis_total']
    gift_cards_redeemed = report['gift_cards_redeemed']
    gift_card_redeem_total = report['gift_card_redeem_total']
    gift_cards_sold = report['gift_cards_sold']
    gift_card_sales_total = report['gift_card_sales_total']
    refund_order_items  =  report['refund_order_items']
    aconto_order_items  =  report['aconto_order_items']
    aconto_total  =  report['aconto_total']
    revenue =   report['revenue']
    transactions   = report['transactions']
    transactions_sum   = report['transactions_sum']
    calculated_drawer_amount =   report['calculated_drawer_amount']
    categories_sum = report['categories_sum']
    
    date_from = report[:date_from]
    date_to = report[:date_to]
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
        "#{ I18n.t 'vendors.report_day.count_orders' }: #{ report['count_orders'] }\n" +
        "#{ I18n.t 'vendors.report_day.count_order_items' }: #{ report['count_order_items'] }\n\n"


    
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
      
      groups[type] +=
          group_header +
          category_header +
          category_lines +
          "\n" +
          taxes_header +
          taxes_lines
    end
      
    
    revenue_header = "\n"
    revenue_header +=
        "\e!\x18" +
        I18n.t('printr.eod_report.revenue') + 
        "\e!\x00"
    
    revenue_lines = "\n"
    revenue_lines +=
        line_format2 % [
          I18n.t('vendors.report_day.gross'),
          report[:unit],
          revenue[:gro]
        ]
    revenue_lines +=
        line_format2 % [
          I18n.t('vendors.report_day.net'),
          report[:unit],
          revenue[:net]
        ]

    
    
    payments_header = I18n.t('vendors.report_day.sums_by_payment_methods')
    payments_lines = "\n"
    paymentmethods.each do |k,v|
      payments_lines +=
        line_format2 % [
          v[:name],
          '',
          v[:amount]
        ]
    end
    aconto_order_items.each do |k,v|
      payments_lines +=
        line_format2 % [
          I18n.t('vendors.report_day.as_aconto_from'),
          '',
          v[:amount]
        ]
    end
    
    if gift_cards_redeemed.any?
      giftcards_redeemed_header = I18n.t('.gift_card_redeem_total')
      giftcards_redeemed_lines = "\n"
      gift_cards_redeemed.each do |gc|
        giftcards_redeemed_lines +=
          line_format2 % [
            gc.sku,
            gc.order.nr,
            -gc.total.to_f
          ]
      end
    end
    
    if gift_cards_sold.any?
      giftcards_sold_header = I18n.t('.gift_card_sales_total')
      giftcards_sold_lines = "\n"
      gift_cards_sold.each do |gc|
        giftcards_sold_lines +=
          line_format2 % [
            gc.sku,
            gc.order.nr,
            gc.total.to_f
          ]
      end
    end
            
      
    
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
        revenue_header +
        revenue_lines +
        payments_header +
        payments_lines +
        giftcards_redeemed_header.to_s +
        giftcards_redeemed_lines.to_s +
        giftcards_sold_header.to_s +
        giftcards_sold_lines.to_s +
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
      @customers = self.company.customers.visible.where(:id => params[:id])
    end
    
    @currency = I18n.t('number.currency.format.friendly_unit', :locale => self.region)
    template = File.read("#{Rails.root}/app/views/printr/#{ model }_#{params[:type]}_#{params[:style]}.prnt.erb")
    erb = ERB.new(template, 0, '>')
    text = erb.result(binding)
      
    if params[:download] == 'true'
      return Escper::Asciifier.new.process(text)
    elsif cash_register.salor_printer
      return Escper::Asciifier.new.process(text) * params[:copies].to_i
    elsif self.company.mode == 'local'
      if params[:type] == 'sticker'
        printer_path = cash_register.sticker_printer
      else
        printer_path = cash_register.thermal_printer
      end
      
      params[:copies] ||= 1

      vp = Escper::VendorPrinter.new({})
      vp.id = 0
      vp.name = cash_register.name
      vp.path = printer_path
      vp.copies = params[:copies].to_i
      vp.codepage = 0
      vp.baudrate = 9600
      
      
      SalorBase.log_action "[Vendor#print_labels]: #{ vp.inspect }"
      
      print_engine = Escper::Printer.new(self.company.mode, vp, File.join(SalorRetail::Application::SR_DEBIAN_SITEID, self.hash_id))
      print_engine.open
      print_engine.print(0, text)
      print_engine.close
    end
  end
  
  def set_hash_id
    hid = read_attribute :hash_id
    unless hid.blank?
      ActiveRecord::Base.logger.info "hash_id is already set."
      return
    end
    self.hash_id = "#{ self.identifier }#{ generate_random_string[0..20] }"
    ActiveRecord::Base.logger.info "Set hash_id to #{ self.hash_id }."
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
  def check_range(from=nil, to=nil, filter=[:orderItemTaxRoundingNet, :orderItemTaxRounding])
    
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
    
    tests.flatten!
    
    filtered_tests = []
    tests.each do |t|
      if filter.include?(t[:t]) == false
        filtered_tests << t
      end
    end
    
    return filtered_tests.join("\n")
  end
  
  def create_inventory_report
    ir = InventoryReport.new
    ir.vendor = self
    ir.company = self.company
    ir.name = "InventoryReport #{ Time.now.strftime("%Y%m%d") }"
    result = ir.save
    if result != true
      raise "Could not save InventoryReport because #{ ir.errors.messages }"
    end
    
    sql = %Q[
        INSERT INTO inventory_report_items 
        ( inventory_report_id,
          item_id,
          real_quantity,
          quantity,
          created_at,
          updated_at,
          vendor_id,
          company_id,
          price_cents,
          purchase_price_cents,
          category_id,
          name,
          currency,
          tax_profile_id,
          sku
         ) SELECT 
            ir.id,
            i.id,
            i.real_quantity,
            i.quantity,
            NOW(),
            NOW(),
            ir.vendor_id,
            ir.company_id,
            i.price_cents,
            i.purchase_price_cents,
            i.category_id,
            i.name,
            i.currency,
            i.tax_profile_id,
            i.sku FROM
          items AS i, 
          inventory_reports AS ir WHERE 
            i.real_quantity_updated IS TRUE AND 
            ir.id = #{ir.id} AND
            i.hidden IS NULL
    ]
    Item.connection.execute(sql)
    Item.connection.execute("UPDATE items SET quantity = real_quantity, real_quantity_updated = NULL, real_quantity = 0 WHERE real_quantity_updated IS TRUE AND vendor_id=#{ self.id} AND company_id=#{ self.company_id }")
  end
  
  def recurrable_subscription_orders
    self.orders.visible.where(:subscription => true).where("subscription_next <= '#{ (Time.now + 1.day).strftime('%Y-%m-%d') }'")
  end
  
  # outputs total per month
  def recurrable_order_total
    total = self.orders.visible.where(:subscription => true).collect do |o|
      o.total_cents / o.subscription_interval
    end.sum
    return Money.new(total, self.currency)
  end
  
  def csv_dump(model, from, to)
    case model
    when 'OrderItem'
      order_items = self.order_items.visible.where(:created_at => from..to)
      attributes = "order.nr;created_at;order.user.username;quantity;total_cents;tax_amount"
      output = ''
      output += "#{attributes}\n"
      output += Report.to_csv(order_items, OrderItem, attributes)
    when 'Item'
      items = self.items.visible
      attributes = "id;sku;name;description;price_cents;location.name;category.name;tax_profile.value;quantity;quantity_sold;shipper.name;shipper_sku;packaging_unit"
      output = ''
      output += "#{attributes}\n"
      output += Report.to_csv(items, Item, attributes)
    else
      output = nil
    end
    return output
  end

  def fisc_dump(from, to, location)
    tmppath = SalorRetail::Application.config.paths['tmp'].first
    
    label = "salor-retail-fiscal-backup-#{ I18n.l(Time.now, :format => :datetime_iso2) }"
    dumppath = File.join(tmppath, label)
    FileUtils.mkdir_p(dumppath)
      
    # DUMP DATABASE
    dbconfig = YAML::load(File.open(SalorRetail::Application.config.paths['config/database'].first))
    sqldump_in_tmp = File.join(tmppath, 'database.sql')
    mode = ENV['RAILS_ENV'] ? ENV['RAILS_ENV'] : 'development'
    username = dbconfig[mode]['username']
    password = dbconfig[mode]['password']
    database = dbconfig[mode]['database']
    `mysqldump -u #{username} -p#{password} #{database} > #{dumppath}/database.sql`

    
    # DUMP LOGFILE
    logfile = SalorRetail::Application.config.paths['log'].first
    logfile_basename = File.basename(logfile)
    logfile_in_tmp = File.join(tmppath, logfile_basename)
    FileUtils.cp(logfile, dumppath)
    

    # GENERATE CSV FILES
    Report.dump_all(self, from, to, dumppath)
    
    # ZIP IT UP
    zip_outfile = "#{ location }/#{ label }.zip"
    Dir.chdir(dumppath)
    `zip -r #{ zip_outfile } .`
    `chmod 777 #{ zip_outfile }`
    
    FileUtils.rm_r dumppath # causes exception
    
    return zip_outfile
  end
  
  def paths
    paths = {
      :uploads        => File.join(Rails.root, "public", "uploads", SalorRetail::Application::SR_DEBIAN_SITEID, self.hash_id),
      :plugins        => File.join(Rails.root, "public", "uploads",SalorRetail::Application::SR_DEBIAN_SITEID, self.hash_id, "plugins"),
    }
    return paths
  end
  
  def urls
    urls = {
      :uploads        => "/uploads/#{ SalorRetail::Application::SR_DEBIAN_SITEID }/#{ self.hash_id }",
      :plugins        => "/uploads/#{ SalorRetail::Application::SR_DEBIAN_SITEID }/#{ self.hash_id }/plugins",
    }
    return urls
  end
  
  def to_json
    attrs = {
      :id => self.id,
      :largest_order_number => self.largest_order_number,
    }
    return attrs.to_json
  end
  
  private
  
  def generate_random_string
    collection = [('a'..'z'),('A'..'Z'),('0'..'9')].map{|i| i.to_a}.flatten
    (0...128).map{ collection[rand(collection.length)] }.join
  end
end
