# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

# {VOCABULARY} employee_info user_info user_deeds user_can_do user_cannot_do employee_can_do
# {VOCABULARY} generate_encrypted_password decrypt_password digest_password
module UserEmployeeMethods
  def self.included(mod)
    def User.generate_password(string)
      return Digest::SHA2.hexdigest("#{string}")
    end
    def Employee.generate_password(string)
      return Digest::SHA2.hexdigest("#{string}")
    end
    mod.class_eval do
      def generate_password(string)
        return Digest::SHA2.hexdigest("#{string}")
      end
      def get_meta
        if self.meta.nil? then
          self.meta = Meta.new
          self.save
          return self.meta
        else
          return self.meta
        end
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
          if SalorBase.check_code(string) == false then
            self.errors[:password] << "incorrect format"
            return
          end
          self.encrypted_password_will_change!
          write_attribute(:encrypted_password,self.generate_password(string))
        end
      end
      def password
        ""
      end
    end # end class_eval
  end # end self.included
  #
  #
  def cute_credit_messages
    config = ActiveRecord::Base.configurations[Rails.env].symbolize_keys
    conn = Mysql2::Client.new(config)
    oids = []
    self.orders.select(:id).where(:paid => 1, :created_at => Time.now.beginning_of_day..Time.now).each do |o|
      oids << o.id
    end
    sql = "SELECT * FROM cute_credit.cute_credit_messages WHERE ref_id IN (#{oids.join(',')})"
    messages = conn.query(sql)
    return messages
  end
  #
  #
  # {START}
  def employee_select(opts={})
    user = self.get_owner
    emps = Employee.scopied.all
    if opts[:name] then
      name = "#{opts[:name]}[set_owner_to]"
    else
      name = "set_owner_to"
    end
    opts[:id] ||= "set_owner_to"
    opts[:class] ||= "set-owner-to"
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
  def make_valid
    if self.drawer.nil? then
      self.drawer = Drawer.new
      self.drawer.save
    end
    if self.meta.nil? then
      self.meta = Meta.new
      self.meta.save
    end
  end
  def full_name
  	return self.first_name + " " + self.last_name if self.class == Employee
  	return self.username
  end
  def is_owner?
	  return true if self.class == User
	  return false
  end
  def is_employee?
    return true if self.class == Employee
	  return false
  end
  def get_theme
    return '/overcast'
  end
  def set_theme(tname)
    update_attribute(:theme,tname)
  end
  def add_vendor(name)
  	  v = Vendor.new(:name => name)
  	  v.user = self if self.class == User
  	  v.user = self.user if self.class == Employee
  	  v.salor_configuration = SalorConfiguration.new
  	  v.save!
  	  return v
  end
  # Remember these functions need to be implemented in Employee, so consider
  # them an Interface
  
  def get_discounts
    if $Params[:page] then
      return Discount.scopied.order("id DESC").page($Params[:page]).per($Conf.pagination)
    else
      return Discount.scopied.order("id DESC")
    end
  end
  
  def get_discount(id)
    if Discount.exists? id then
      return Discount.scopied.find_by_id(id)
    else
      return Discount.new
    end
  end
  
  def get_shippers(page)
    return Shipper.scopied.order("id DESC").page($Params[:page]).per($Conf.pagination)
  end

  def get_default_vendor
    if self.vendors.any? then
      return self.vendors.first
    else
      return add_vendor("My First Store")
    end
  end
  
  # Items related functions
  def get_items
    return Item.where("sku NOT LIKE 'DMY%'").order(AppConfig.items.order).scopied.page($Params[:page]).per($Conf.pagination)
  end
  def get_item(id)
    i = Item.scopied.where(["id = ?",id]) 
    if not i then
      i = Item.scopied.where(["sku = ?",id]) 
    end
    if i.first then
       i = i.first
    else
       i = nil
    end
    return i if i and i.respond_to? :vendor_id and owns_vendor?(i.vendor_id)
    return nil
  end

  # ShipmentTypes
  def get_shipment_types
    return ShipmentType.scopied.order("name ASC").page($Params[:page]).per($Conf.pagination)
  end
  def get_shipment_type(id)
    c = ShipmentType.scopied.find_by_id(id)
    return c
  end
  def get_all_shipment_types
    stypes = ShipmentType.order("id DESC").where(:vendor_id => $Vendor.id)
    
    stypes.unshift ShipmentType.new(:name => ' ')
    return stypes
  end
  #Category related functions
  def get_categories(page=nil)
    return Category.scopied.order("id DESC").page($Params[:page]).per($Conf.pagination)
  end
  def get_all_categories
    cats = Category.by_vendor.order("id DESC")
    cats.unshift Category.new(:name => ' ')
    return cats
  end
  def get_category(id)
    c = Category.scopied.find_by_id(id)
    return c
  end
  def get_customers(page=nil)
    return Customer.scopied.order('id DESC').page($Params[:page]).per($Conf.pagination)
  end
  
  # Locations related functions
  def get_locations(page=nil)
    id = GlobalData.salor_user.meta.vendor_id
    return Location.scopied.order('id DESC').page($Params[:page])
  end
  def get_location(id)
    l = Location.scopied.find(id)
    return l if owns_vendor?(l.vendor_id)
    return Location.new
  end
  
  # TaxProfiles related functions
  def get_tax_profiles
    return TaxProfile.scopied 
  end
  def get_tax_profile(id)
    tp = TaxProfile.scopied.find_by_id(id)
    tp = TaxProfile.new if not tp
    return tp
  end
  
  # Orders related functions
  def get_orders
    return Order.order("id DESC").scopied.page($Params[:page]).per($Conf.pagination)
  end
  def get_order(id)
    order = Order.includes(:order_items,:coupons,:gift_cards).find_by_id(id)
    return order 
  end
  def get_new_order
    # puts "##Creating a new order"
    o = Order.new
    if owns_vendor?(GlobalData.salor_user.meta.vendor_id) then
      o.vendor_id = GlobalData.salor_user.meta.vendor_id
    else
      o.vendor_id = get_default_vendor.id
    end
    o.set_model_owner(self)
    o.cash_register_id = GlobalData.salor_user.meta.cash_register_id
    o.save!
    GlobalData.salor_user.meta.update_attribute :order_id,o.id
    return o
  end
  
  # Vendors related functions
  def get_vendors(page)
    if page.nil? then
      return self.vendors.visible
    else
      return self.vendors.visible.page(page).per($Conf.pagination)
    end
  end
  def get_vendor(id)
    ven = Vendor.find(id)
    return ven if owns_vendor?(ven.id)
    return Vendor.new
  end
  
  def get_new_cash_register_daily
    d = CashRegisterDaily.new(:start_amount => 0, :end_amount => 0, :cash_register_id => GlobalData.session.cash_register_id)
    d.user_id = self.id if self.class == User
    d.employee_id = self.id if self.class == Employee
    d.save
    return d
  end
  
  # Employees related functions
  def get_employees(id,page)
    return Employee.scopied.page(page).per($Conf.pagination)
  end
  def get_employee(id)
    employee = Employee.find(id)
    return employee if employee.user_id = self.id
    return Employee.new
  end
  
  def get_owner
    return self if self.class == User
    return self.user if self.class == Employee
    return self.employee if self.respond_to? :employee_id
    return self.user
  end
  
  def get_drawer
    # This method allows for more than one user to have money
    # put into the same drawer, i.e. for CigarMan
    if self.class == Employee and self.uses_drawer_id then
      d = Drawer.find_by_id(self.uses_drawer_id)
      return d if d
    end
    if self.drawer.nil? then
      self.drawer = Drawer.new
      self.drawer.save
    end
    return self.drawer
  end
  
  def can(action)
    if self.class == User or AppConfig.roleless == true then
      return true
    else
      action = action.to_s
      admin = 'manager'
      any = nil
      if action.match(/new|index|edit|destroy|create|update|show/) then
        any = action.gsub(/new|index|edit|destroy|create|update|show/,'any')
      else
        # puts "No Match for #{action}"
      end
      any = 'xxxxxxxxxxxxxxxxx' if any.nil?
      if self.role_cache.include?(action) or self.role_cache.include?(admin) or self.role_cache.include?(any)
#          puts "Role #{action} allowed."
        return true
      else
        # the role isn't on the model, so let's see if
        # they are prevented from this action
        self.role_cache.split(',').each do |role|
          cnts = Role::CANNOTDO[role.to_sym]          
          if cnts then
            if cnts.include? action.to_sym or cnts.include? any.to_sym or cnts.include? :anything then
#               puts "Returning false from cannot do... #{action}"
              return false
            end
          end            
        end
#         puts "Cants didn't trip, returning true"
        return true
      end
    end
    return true
  end
  def owns_vendor?(id)
    if self.class == User then
      vs = self.vendors
    else
      vs = self.user.vendors
    end
    vs.each do |v|
      if v.id == id.to_i then
        return true
      end
    end
    return false
  end
  def owns_this?(model)
    if model.class == LoyaltyCard then
      return owns_this?(model.customer)
    end
    if model.respond_to? :vendor_id and not model.vendor_id.nil?
      return true if owns_vendor?(model.vendor_id)  
    end
    if model.respond_to? :user_id then
      return true if self.class == User and model.user_id == self.id
      return true if self.class == Employee and model.user_id == self.user.id
    end
   
    if model.respond_to? :employee_id then
       if self.class == User
         if Employee.exists?(model.employee_id) then
           begin
             emp = Employee.find(model.employee_id) 
           rescue
             return false
           end
           if emp then
             return true if emp.user_id == self.id
           end
         end
       end
       return true if self.id == model.employee_id
       return false
    end
    if model.class == ShipmentItem then
      return owns_this?(model.shipment)
    end
    if model.class == OrderItem then
      return owns_this?(model.order)
    end
    return false
  end
  
  #
  
  def get_root
    return :controller => 'vendors' if self.class == User
    self.roles.each do |role|
      # puts "GetRoot evaluating role: #{role.name}"
      if role.name == 'manager' then
        return :controller => 'vendors',:action => :show, :id => self.vendor_id
      end
      if role.name == 'cashier' or role.name == 'head_cashier' then
        return :controller => 'cash_registers'
      elsif role.name == 'stockboy' then
        return :controller => 'shipments'
      end
    end
    return nil #i.e. we don't know what they are up too
  end
  
  def end_day
    if Order.exists? self.meta.order_id then
      o = Order.find_by_id(self.meta.order_id)
      if not o.nil? then
        o.total = 0 if o.total.nil? 
        if o.total == 0 and not o.order_items.visible.any? then
          #o.destroy Removed to comply with FISC laws, orders can no longer be destroyed in the system.
        else
          # puts "##Order.total = #{o.total} and has #{o.order_items.any?}"
        end
      end
    else
      # puts "##OrderDoesNotExist"
    end
    vendor_id = self.meta.vendor_id
    cash_register_id = self.meta.cash_register_id
    self.meta.order_id = nil
    self.meta.last_order_id = nil
    self.meta.cash_register_id = nil
    self.meta.save
    self.update_attribute :last_path,''
  end
  
  def best_sellers
    if self.class == User then
      return self.items.order('quantity_sold DESC').limit(10)
    else
      return self.user.items.order('quantity_sold DESC').limit(10)
    end
  end
  
  def almost_out
    if self.class == User then
      return self.items.where("quantity < min_quantity AND ignore_qty = 0 AND (active IS TRUE or active = 1)").order('quantity ASC').page($Params[:page]).per(10)
    else
      return self.user.items.where("quantity < min_quantity AND ignore_qty = 0 AND (active IS TRUE or active = 1)").order('quantity ASC').page($Params[:page]).per(10)
    end
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
      total_ever = self.orders.where("refunded = 0 and paid = 1").sum(:total)
      total_today = self.orders.where("refunded = 0 and paid = 1 and created_at > '#{Time.now.beginning_of_day}'").sum(:total)
      totals = [total_ever.first,total_today.first]
    rescue
      
    end
    totals[0] = 0 if totals[0].nil?
    totals[1] = 0 if totals[1].nil?
    return totals
  end

  #
  def self.get_end_of_day_report(from,to,employee)
    categories = Category.scopied
    taxes = TaxProfile.scopied.where( :hidden => 0 )
    if employee
      orders = Order.scopied.where({ :vendor_id => employee.get_meta.vendor_id, :drawer_id => employee.get_drawer.id,:created_at => from.beginning_of_day..to.end_of_day, :paid => 1 }).order("created_at ASC")
      drawertransactions = DrawerTransaction.where({:drawer_id => employee.get_drawer.id, :created_at => from.beginning_of_day..to.end_of_day }).where("tag != 'CompleteOrder'")
    else
      orders = Order.scopied.where({ :vendor_id => $Vendor.id,:created_at => from.beginning_of_day..to.end_of_day, :paid => 1 }).order("created_at ASC")
      drawertransactions = DrawerTransaction.where({:created_at => from.beginning_of_day..to.end_of_day }).where("tag != 'CompleteOrder'")
    end
    regular_payment_methods = PaymentMethod.types_list.collect{|pm| pm[1].to_s }

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
        elsif p.internal_type == 'InCash'
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
      end

      o.order_items.visible.each do |oi|
        catname = oi.category ? oi.category.name : ''
        taxname = oi.tax_profile.name
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
    paymentmethods[:pos]['InCash'] = categories_sum[:pos][:gro] - paymentmethods[:pos].to_a.collect{|x| x[1]}.sum

    categories_sum[:neg][:gro] = categories[:neg].to_a.collect{|x| x[1][:gro]}.sum
    categories_sum[:neg][:net] = categories[:neg].to_a.collect{|x| x[1][:net]}.sum
    paymentmethods[:neg]['InCash'] = categories_sum[:neg][:gro] - paymentmethods[:neg].to_a.collect{|x| x[1]}.sum

    transactions = Hash.new
    transactions_sum = { :drop => 0, :payout => 0, :total => 0}
    drawertransactions.each do |d|
      transactions[d.id] = { :drop => d.drop, :is_refund => d.is_refund, :time => d.created_at, :notes => d.notes, :tag => d.tag, :amount => d.amount }
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
    calculated_drawer_amount = transactions_sum[:drop] + transactions_sum[:payout] + refunds[:cash][:gro] + paymentmethods[:pos]['InCash'] + paymentmethods[:neg]['InCash']

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
    if employee
      report[:drawer_amount] = employee.get_drawer.amount
      report[:username] = "#{ employee.first_name } #{ employee.last_name } (#{ employee.username })"
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
      #r[:order_items_count] = OrderItem.connection.execute("select count(oi.id) from order_items as oi, orders as o, vendors as v where v.id IN (#{self.get_owner.vendor_ids.join(',')}) and o.vendor_id = v.id and oi.order_id = o.id").to_a.first.first
    rescue
      r[:order_items_count] = 0
    end
    r[:items_count] = Vendor.scopied.each.inject(0) {|x,v| x += v.items.where("behavior != 'coupon'").count}
    r[:items_zero_count] = Vendor.scopied.each.inject(0) {|x,v| x += v.items.where('quantity <= 0').count}
    r = no_nils(r)
    return r
  end
  def is_technician?
    if self.class == User and self.is_technician == true then
      return true
    else
      return false
    end
  end
  def auto_drop
    return
    if $Conf and $Conf.auto_drop then
      bod = DrawerTransaction.where(:tag => 'beginning_of_day', :drawer_id => GlobalData.salor_user.get_drawer.id).order("id desc").limit(1)
      last_eod = DrawerTransaction.where(:tag => 'end_of_day', :drawer_id => GlobalData.salor_user.get_drawer.id).order("id desc").limit(1)
      if last_eod.any? and (not bod.any? or bod.first.id < last_eod.first.id) then
        amount = last_eod.first.amount
        dt = DrawerTransaction.new(:owner_type => self.class.to_s,
                                   :owner_id => self.id,
                                   :drop => true,
                                   :amount => amount,
                                   :drawer_id => self.get_drawer.id,
                                   :drawer_amount => self.get_drawer.amount,
                                   :cash_register_id => self.meta.cash_register_id,
                                   :tag => "beginning_of_day")
        if not dt.save then
          GlobalErrors.append("system.errors.auto_drop_failed",self,nil)
        else
          GlobalData.salor_user.get_drawer.update_attribute(:amount,GlobalData.salor_user.get_drawer.amount + dt.amount)
          atomize(ISDIR, 'cash_drop')
        end
      else
        GlobalErrors.append("system.errors.auto_drop_failed2",self,nil)
      end
    else
      # puts "Autodrop not set"
    end
  end
  def set_role_cache
    rs = []
    self.roles.each do |r|
      rs << r.name
    end
    self.role_cache = rs.join(',')
  end
  # {END}
end
