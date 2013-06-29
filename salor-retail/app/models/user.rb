# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

require 'digest/sha2'
class User < ActiveRecord::Base

  include SalorScope
  include SalorBase

  
  belongs_to :vendor
  belongs_to :company
  
  
  has_one :drawer

  
  validate :validify

  has_many :orders
  has_many :order_items
  has_many :receipts
  has_many :vendors, :through => :user
  has_many :paylife_structs, :as => :user
  has_many :current_register_dailies
  has_and_belongs_to_many :roles
  
  has_many :drawer_transactions, :as => :user
  has_many :histories, :as => :user
  has_many :user_logins
  # Setup accessible (or protected) attributes for your model
  #attr_accessible :uses_drawer_id,:apitoken,:js_keyboard,:role_ids,:language,:vendor_id,:user_id,:first_name,:last_name,:username, :email, :password, :password_confirmation, :remember_me, :hourly_rate
  #attr_accessible :auth_code
  before_update :set_role_cache
  before_save :set_role_cache

  
  def self.generate_password(string)
    return Digest::SHA2.hexdigest("#{string}")
  end
  
  def self.find_for_authentication(conditions={})
    conditions[:hidden] = false
    find(:first, :conditions => conditions)
  end 
  
  def self.login(pass)
    user = self.find_by_encrypted_password(self.generate_password(pass))
    return user
  end
  
  def password=(string)
    if string == '000' then
      write_attribute :encrypted_password, generate_password(rand(900000))
      return
    end
    string = string.strip
    if not string.empty? then
      self.encrypted_password_will_change!
      write_attribute(:encrypted_password,self.generate_password(string))
    end
  end
  
  def password
    ""
  end
  
  def validify
    if self.email.blank? then
      e = Digest::SHA256.hexdigest(Time.now.to_s)[0..12]
      self.email = "#{e}@salorpos.com"
    end
    login = self.user_logins.last
    if login then
      login.hourly_rate = self.hourly_rate
      login.save
    end
  end
  
  def make_token
    if self.apitoken.blank? then
      self.apitoken = ''
      t= rand(36**24).to_s(36)
      m = ['!','@','#','$','%','^','&','*','(','/','{','"$5%','/#!5','3&^','10%*@','z&6$!`']
      ls = ''
      t.each_char do |c|
        if rand(100) < 48 then
          c = c.upcase
        end
        if rand(100) < 67 then
          self.apitoken << m[rand(m.length-1)]
        end
        if c == ls then
          self.apitoken << m[rand(m.length-1)]
        end
        self.apitoken << c
        ls = c
      end
    end
    self.apitoken
  end

  def name_with_username
    "#{ first_name } #{ last_name } (#{ username })"
  end
  
  def debug_info
    text  = "#{self.last_name}, #{self.first_name} as #{self.username}: \n"
    text += "\tDrawer: #{self.drawer.id} Actual: #{self.get_drawer.id}\n"
    text += "\tOrders: #{self.orders.order('created_at desc').limit(5).collect {|o| o.id }.join(',') }\n"
    return text
  end
  
  def user_select(opts={})
    user = self.get_user
    emps = User.scopied.all
    if opts[:name] then
      name = "#{opts[:name]}[set_user_to]"
    else
      name = "set_user_to"
    end
    opts[:id] ||= "set_user_to"
    opts[:class] ||= "set-user-to"
    txt = "<select name='#{name}' id='#{opts[:id]}' class='#{opts[:class]}'>"
    options = []
    if self == user then
      options << "<option value='#{self.class}:#{self.id}' selected='selected'>#{self.username}</option>"
    else
      options << "<option value='#{user.class}:#{user.id}'>#{user.username}</option>"
    end
    emps.each do |emp|
      if self == emp then
        options << "<option value='#{emp.class}:#{emp.id}' selected='selected'>#{emp.username}</option>"
      else
        options << "<option value='#{emp.class}:#{emp.id}'>#{emp.username}</option>"
      end
    end
    return txt + options.join("\n") + "</select>"
  end

  
  def full_name
    return self.first_name + " " + self.last_name if self.class == User
    return self.username
  end


  
  # Orders related functions
  def get_orders
    return Order.order("id DESC").scopied.page($Params[:page]).per($Conf.pagination)
  end

  
  def get_new_current_register_daily
    d = CashRegisterDaily.new(:start_amount => 0, :end_amount => 0, :current_register_id => GlobalData.session.current_register_id)
    d.user_id = self.id
    d.save
    return d
  end
  
  # Users related functions
  def get_users(id,page)
    return User.scopied.page(page).per($Conf.pagination)
  end
  
  def get_user(id)
    user = User.find(id)
    return user if user.user_id = self.id
    return User.new
  end
  
  def get_drawer
    if self.uses_drawer_id then
      return self.vendor.drawers.find_by_id(self.uses_drawer_id)
      return d if d
    end
    return self.drawer
  end
  
  def can(action)
    if self.role_cache.include? "manager" then
      return true
    else
      action = action.to_s
      admin = 'manager'
      any = nil
      if not (action.to_s.include? "destroy_users" or action.to_s.include? "edit_users" or action.to_s.include? "create_users") then
        if self.role_cache.include? "assistant" then
          return true
        end
      end
      if action.match(/new|index|edit|destroy|create|update|show/) then
        any = action.gsub(/new|index|edit|destroy|create|update|show/,'any')
      else
        # puts "No Match for #{action}"
      end
      
      any = 'xxxxxxxxxxxxxxxxx' if any.nil?
      if self.role_cache.include?(action) or self.role_cache.include?(admin) or self.role_cache.include?(any)
#         puts "Returning true for #{action} #{any} #{self.role_cache}"
        return true
      else
        role_list = self.role_cache.split(',').map {| r | r.to_sym}
        role_list.each do |r|
          cant_do_list = Role::CANNOTDO[r]
          return false if cant_do_list.include? :anything
          next if cant_do_list.nil?
#           puts "Seeing if "
          if cant_do_list.include? action.to_sym then
            return false
          end
          if cant_do_list.include? any.to_sym then
            return false
          end
        end 
      end
    end
    puts "Returning default true for #{action} #{any} #{self.role_cache}"
    return true
  end
  
  def owns_vendor?(id)
    return self.vendor_id == id
  end
  
  def owns_this?(model)
    
    if model.class == LoyaltyCard then
      return owns_this?(model.customer)
    end
    if model.respond_to? :vendor_id and not model.vendor_id.nil?
      return true if owns_vendor?(model.vendor_id)  
    end
    if model.respond_to? :user_id then
      return true if self.class == User and model.user_id == self.user.id
    end
   
    if model.respond_to? :user_id then
       return model.user_id == self.id
    end
    if model.class == ShipmentItem then
      return owns_this?(model.shipment)
    end
    if model.class == OrderItem then
      return owns_this?(model.order)
    end
    raise "You cannot do what you are trying to do. Please stop."
    return false
  end
  
  def end_day
    login = self.user_logins.last
    if login then
      login.logout = Time.now
      login.save
    end
  end
  
  def start_day
    login = self.user_logins.last
    return if login and login.logout.nil?
    login = UserLogin.new
    login.user_id = self.id
    login.hourly_rate = self.hourly_rate
    login.login = Time.now
    login.vendor_id = self.vendor_id
    login.save
  end
  
  def best_sellers
      return self.user.items.order('quantity_sold DESC').limit(10)
  end
  
  def almost_out
      return self.user.items.where("quantity < min_quantity AND ignore_qty = 0 AND (active IS TRUE or active = 1)").order('quantity ASC').page($Params[:page]).per(10)
  end
  
  def best_selling_categories
    return Category.scopied.order("cash_made DESC").limit(10)
  end
  
  def best_selling_locations
    return Location.scopied.order("cash_made DESC").limit(10)
  end
  # {END}
  def expiring
    items = []
    cap = Time.now.beginning_of_day + 5.days
    bcap = Time.now.beginning_of_day - 5.days
    Vendor.scopied.each do |vendor|
      vendor.items.where("expires_on between '#{bcap.strftime("%Y-%m-%d")}' and '#{cap.strftime("%Y-%m-%d")}' and (active IS TRUE or active = 1)").each do |item|
        items << item
      end
    end
    return items
  end
  # {START}
  def get_order_totals
    totals = []
    begin
      total_ever = self.orders.where(:paid => 1, :unpaid_invoice => false, :is_quote => false, :refunded => 0).sum(:total)
      total_today = self.orders.where(:paid => 1, :unpaid_invoice => false, :is_quote => false, :refunded => 0).where("created_at > '#{Time.now.beginning_of_day}'").sum(:total)
      totals = [total_ever.first,total_today.first]
    rescue
      
    end
    totals[0] = 0 if totals[0].nil?
    totals[1] = 0 if totals[1].nil?
    return totals
  end

  #
  def self.get_end_of_day_report(from,to,user)
    categories = Category.scopied
    taxes = TaxProfile.scopied.where( :hidden => 0 )
    if user
      orders = Order.scopied.where({ :vendor_id => user.get.vendor_id, :drawer_id => user.get_drawer.id, :created_at => from.beginning_of_day..to.end_of_day, :paid => 1, :unpaid_invoice => false, :is_quote => false }).order("created_at ASC")
      drawertransactions = DrawerTransaction.where({:drawer_id => user.get_drawer.id, :created_at => from.beginning_of_day..to.end_of_day }).where("tag != 'CompleteOrder'")
    else
      orders = Order.scopied.where({ :vendor_id => $Vendor.id, :created_at => from.beginning_of_day..to.end_of_day, :paid => 1, :unpaid_invoice => false, :is_quote => false  }).order("created_at ASC")
      drawertransactions = DrawerTransaction.where({:created_at => from.beginning_of_day..to.end_of_day }).where("tag != 'CompleteOrder'")
    end
    regular_payment_methods = PaymentMethod.types_list.collect{|pm| pm[1].to_s }

    categories = {:pos => {}, :neg => {}}
    taxes = {:pos => {}, :neg => {}}
    paymentmethods = {:pos => {}, :neg => {}, :refund => {}}
    refunds = { :cash => { :gro => 0, :net => 0 }, :noncash => { :gro => 0, :net => 0 }}

    orders.each do |o|
      o.sanity_check # Check to see if the payment methods on the order are insane due to Arel errors.
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
          if not $Conf.calculate_tax then
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


  #
  def report
    r = {}
    r[:orders_total] = Order.scopied.where("paid = 1 and refunded = 0").sum(:total)
    r[:orders_count] = Order.scopied.where("paid = 1 and refunded = 0").count
    begin
      total = 0
      Vendor.scopied.each do |v|
        r[:order_items_count] = v.orders.each.inject(0) {|x,o| x += o.order_items.visible.where('refunded = 0').count}
      end
      #r[:order_items_count] = OrderItem.connection.execute("select count(oi.id) from order_items as oi, orders as o, vendors as v where v.id IN (#{self.get_user.vendor_ids.join(',')}) and o.vendor_id = v.id and oi.order_id = o.id").to_a.first.first
    rescue
      r[:order_items_count] = 0
    end
    r[:items_count] = Vendor.scopied.each.inject(0) {|x,v| x += v.items.where("behavior != 'coupon'").count}
    r[:items_zero_count] = Vendor.scopied.each.inject(0) {|x,v| x += v.items.where('quantity <= 0').count}
    r = no_nils(r)
    return r
  end


  
  def set_role_cache
    rs = []
    self.roles.each do |r|
      rs << r.name
    end
    self.role_cache = rs.join(',')
  end

end
