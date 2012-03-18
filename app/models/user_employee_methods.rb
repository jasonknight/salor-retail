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
          write_attribute :encripted_password, generate_password(rand(900000))
          return
        end
        string = string.strip.to_i.to_s
        if not string.empty? and not string.length < 11 then
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
    if GlobalData.params.page then
      return Discount.scopied.order("id DESC").page(GlobalData.params.page).per(GlobalData.conf.pagination)
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
    return Shipper.scopied.order("id DESC").page(GlobalData.params.page).per(GlobalData.conf.pagination)
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
    return Item.where("sku NOT LIKE 'DMY%'").order(AppConfig.items.order).scopied.page(GlobalData.params.page).per(GlobalData.conf.pagination)
  end
  def get_item(id)
    i = Item.scopied.where(["id = ?",id]) 
    if not i then
      i = Item.scopied.where(["sku = ?",id]) 
    end
    if i.first then
       i = i.first
      end
    return i if i and owns_vendor?(i.vendor_id)
    return nil
  end

  # ShipmentTypes
  def get_shipment_types
    return ShipmentType.scopied.order("name ASC").page(GlobalData.params.page).per(GlobalData.conf.pagination)
  end
  def get_shipment_type(id)
    c = ShipmentType.scopied.find_by_id(id)
    return c
  end
  def get_all_shipment_types
    stypes = ShipmentType.order("id DESC").where(:user_id => GlobalData.salor_user.get_owner.id)
    
    stypes.unshift ShipmentType.new(:name => ' ')
    return stypes
  end
  #Category related functions
  def get_categories(page=nil)
    return Category.scopied.order("id DESC").page(GlobalData.params.page).per(GlobalData.conf.pagination)
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
    return Customer.scopied.order('id DESC').page(GlobalData.params.page).per(GlobalData.conf.pagination)
  end
  
  # Locations related functions
  def get_locations(page=nil)
    id = GlobalData.salor_user.meta.vendor_id
    return Location.scopied.order('id DESC').page(GlobalData.params.page)
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
    tp = TaxProfile.scopied.find(id)
    return tp if tp.user_id == self.id and self.class == User
    return tp if tp.user_id == self.user.id and self.class == Employee
    return TaxProfile.new
  end
  
  # Orders related functions
  def get_orders
    return Order.order("id DESC").scopied.page(GlobalData.params.page).per(GlobalData.conf.pagination)
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
    return Employee.scopied.page(page).per(GlobalData.conf.pagination)
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
      d = Drawer.find_by_id self.uses_drawer_id
      return d if d
    end
    if self.drawer.nil? then
      self.drawer = Drawer.new
      self.drawer.save
    end
    return self.drawer
  end
  
  def can(action)
    puts "Called for: #{action}"
    if self.class == User or AppConfig.roleless == true then
      return true
    else
      action = action.to_s
      admin = Role.find_by_name('manager')
      r = Role.find_by_name action
      any = nil
      if action.match(/new|index|edit|destroy|create|update|show/) then
        a = action.gsub(/new|index|edit|destroy|create|update|show/,'any')
        any = Role.find_by_name(a)
        any = Role.new(:name => a) if any.nil?
      else
        # puts "No Match for #{action}"
      end
      any = Role.new(:name => 'xxxxxxxxxxxxxxxxx') if any.nil?
      if self.roles.include?(r) or self.roles.include?(admin) or self.roles.include?(any)
        # puts "Role #{action} allowed."
        return true
      else
        # the role isn't on the model, so let's see if
        # they are prevented from this action
        self.roles.each do |role|
          cnts = Role::CANNOTDO[role.name.to_sym]          
          if cnts then
            if cnts.include? action.to_sym or cnts.include? any.name.to_sym or cnts.include? :anything then
              return false
            end
          end            
        end
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
        if o.total == 0 and not o.order_items.any? then
          o.destroy
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
      return self.items.where("quantity < min_quantity AND ignore_qty = 0 AND (active IS TRUE or active = 1)").order('quantity ASC').page(GlobalData.params.page).per(10)
    else
      return self.user.items.where("quantity < min_quantity AND ignore_qty = 0 AND (active IS TRUE or active = 1)").order('quantity ASC').page(GlobalData.params.page).per(10)
    end
  end
  
  def best_selling_categories
    return Category.scopied.order("cash_made DESC").limit(10)
  end
  
  def best_selling_locations
    return Location.scopied.order("cash_made DESC").limit(10)
  end
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
  def get_end_of_day_report
    totals = Hash.new()
    totals[:date] = I18n.l(DateTime.now, :format => :long)
    totals[:drawer_amount] = self.get_drawer.amount
    totals[:unit] = I18n.t('number.currency.format.friendly_unit')
    today = Time.now.beginning_of_day.strftime("%Y-%m-%d %H:%M:%S")
    totals[:username] = "#{ self.first_name } #{ self.last_name } (#{ self.username })"

    # Get the orders total
    all_orders = Order.where("employee_id = #{self.id} and created_at > '#{today}' and (paid = 1 or paid IS TRUE)")
    totals[:orders_total] = all_orders.sum(:total)


    # Get the total of refunded order_items
    totals[:refund_total] = 0
    OrderItem.where("created_at > '#{today}' and refunded = 1 and refunded_by = #{self.id}").each do |oi|
      totals[:refund_total] += oi.total
    end

    # Get the total of buyback OrderItems
    bback_total = 0.0
    all_orders.each do |o|
      o.order_items.each do |oi|
        next if oi.refunded or not oi.is_buyback # is_buyback is true
        bback_total += oi.total
      end
    end
    totals[:buyback_item_total] = bback_total

    # Get the total of all drawer transactions for today
    totals[:drop_total] = 0
    totals[:payout_total] = 0
    totals[:payout_refunds] = 0
    self.get_drawer.drawer_transactions.where(["tag <> 'CompleteOrder' and created_at > ? and owner_id = ?",Time.now.beginning_of_day, self.id]).each do |dt|
      totals[:drop_total] += dt.amount if dt.drop
      totals[:payout_total] -= dt.amount if dt.payout
      #totals[:payout_refunds] = totals[:payout_refunds] + dt.amount if dt.payout and dt.is_refund
    end
    totals[:transaction_total] = totals[:payout_total] + totals[:drop_total]

    # Get a LIST of all payout drawer transactions for today
    totals[:dt_payout_list] = Hash.new
    self.get_drawer.drawer_transactions.where(["payout = true and tag <> 'CompleteOrder' and created_at > ? and owner_id = ?", Time.now.beginning_of_day, self.id]).each do |dt|
      totals[:dt_payout_list].merge! dt.id => { :tag => dt.tag, :notes => dt.notes, :time => I18n.l(dt.created_at, :format => :just_time), :amount => - dt.amount, :refund => dt.is_refund }
    end

    # Get a LIST of all drop drawer transactions for today
    totals[:dt_drop_list] = Hash.new
    # ToDo: Can't get the SQL query to work with the word 'drop'
    self.get_drawer.drawer_transactions.where(["(payout = false or payout IS NULL) and is_refund = false and tag <> 'CompleteOrder' and created_at > ? and owner_id = ?", Time.now.beginning_of_day, self.id]).each do |dt|
      totals[:dt_drop_list].merge! dt.id => { :name => dt.tag, :notes => dt.notes, :time => I18n.l(dt.created_at, :format => :just_time), :amount => dt.amount, :refund => dt.is_refund }
    end

    # Get a GROUPED LIST of all positive payment methods for today
    totals[:pm_pos] = Hash.new
    totals[:pm_neg] = Hash.new
    totals[:pm_pos_sum] = 0
    totals[:pm_neg_sum] = 0
    #I18n.t("system.payment_internal_types").split(',').each do |pmtype|
    all_orders.each do |o|
      o.payment_methods.each do |pm|
        next if pm.order_id.nil?
        key = pm.internal_type.to_sym
        if pm.amount > 0
          if not totals[:pm_pos].has_key?(key)
            totals[:pm_pos].merge! key => pm.amount
          else
            totals[:pm_pos][key] += pm.amount
          end
          totals[:pm_pos_sum] += pm.amount
        end
        if pm.amount < 0
          if not totals[:pm_neg].has_key?(key)
            totals[:pm_neg].merge! key => pm.amount
          else
            totals[:pm_neg][key] += pm.amount
          end
          totals[:pm_neg_sum] += pm.amount
        end
      end 
    end
    totals[:pm_sum] = totals[:pm_pos_sum] + totals[:pm_neg_sum]

    totals[:calculated_drawer_amount] = totals[:pm_neg][:InCash] + totals[:pm_pos][:InCash] + totals[:transaction_total]
    return totals
  end
  def report
    r = {}
    r[:orders_total] = Order.scopied.where("paid = 1 and refunded = 0").sum(:total)
    r[:orders_count] = Order.scopied.where("paid = 1 and refunded = 0").count
    begin
      total = 0
      Vendor.scopied.each do |v|
        r[:order_items_count] = v.orders.each.inject(0) {|x,o| x += o.order_items.where('refunded = 0').count}
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
end
