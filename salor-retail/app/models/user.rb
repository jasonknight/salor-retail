# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

require 'digest/sha2'
class User < ActiveRecord::Base
  include SalorScope
  include SalorBase

  has_and_belongs_to_many :vendors
  has_and_belongs_to_many :roles
  
  belongs_to :company
  belongs_to :drawer
  has_many :orders
  has_many :order_items
  has_many :receipts
  has_many :current_register_dailies
  has_many :user_meta
  has_many :drawer_transactions
  has_many :histories
  has_many :user_logins
  
  validates_presence_of :username
  validates_presence_of :company_id
  
  before_update :set_role_cache, :update_hourly_rate
  before_save :set_role_cache, :update_hourly_rate
  before_create :set_id_hash
  
  
  def password=(string)
    string = string.strip
    return if string.empty?
    write_attribute(:encrypted_password, Digest::SHA2.hexdigest(string))
  end
  
  def password
    ""
  end
  
  def update_hourly_rate
    login = self.user_logins.last
    if login then
      login.hourly_rate = self.hourly_rate
      result = login.save
      if result != true
        raise "Could not save UserLogin because #{ login.errors.messages }"
      end
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
  
  def full_name
    return self.first_name.to_s + " " + self.last_name.to_s
  end
  
  def get_drawer
    if self.uses_drawer_id then
      d = self.company.drawers.find_by_id(self.uses_drawer_id)
    else 
      d = self.drawer
    end
    if not d then
      raise "UserHasNoDrawer"
    end
    return d
  end
  
  def drawer_username
    if self.uses_drawer_id then
      d = self.company.drawers.find_by_id(self.uses_drawer_id)
    else 
      d = self.drawer
    end
    if not d then
      raise "UserHasNoDrawer"
    end
    return d.user.username
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
      end
      
      any = 'xxxxxxxxxxxxxxxxx' if any.nil?
      if self.role_cache.include?(action) or self.role_cache.include?(admin) or self.role_cache.include?(any)
        return true
      else
        role_list = self.role_cache.split(',').map {| r | r.to_sym}
        role_list.each do |r|
          cant_do_list = Role::CANNOTDO[r]
          return false if cant_do_list.include? :anything
          next if cant_do_list.nil?
          
          if cant_do_list.include? action.to_sym then
            return false
          end
          if cant_do_list.include? any.to_sym then
            return false
          end
        end 
      end
    end
    return true
  end
  
  def end_day
    login = self.user_logins.last
    if login then
      login.logout = Time.now
      login.save
    end
  end
  
  def start_day(current_vendor)
    login = self.user_logins.last
    return if login and login.logout.nil?
    login = UserLogin.new
    login.company = self.company
    login.vendor = current_vendor
    login.user = self
    login.hourly_rate = self.hourly_rate
    login.login = Time.now
    login.save!
  end
  
  def set_role_cache
    rs = []
    self.roles.each do |r|
      rs << r.name
    end
    self.role_cache = rs.join(',')
  end
  
  def set_drawer
    unless self.drawer
      ActiveRecord::Base.logger.info "User doesn't have a Drawer yet. Creating one"
      d = Drawer.new
      d.company = self.company
      # if a user belongs to several vendors, and those vendors use different currencies, this user should not put money in his drawer, since the drawer total would be the sum of different currencies. we advise customers to create a separate user account (that only belongs to one vendor) for sales instead. they should use the user account that can access several vendor only for administration purposes. In case the different vendors use the same currency, then this is not a problem. by default, the user's drawer will inherit the currency of the first of the user's vendors.
      d.currency = self.vendors.visible.first.currency
      self.drawer = d
      self.drawer.save
      self.save
    end
  end
  
  def set_id_hash
    self.id_hash = generate_random_string[0..20]
  end
  
  def to_json
    {
      :username => self.username,
      :role_cache => self.role_cache
    }.to_json
  end
  
  def drawer_transact(amount_cents, cash_register, tag='', notes='', order=nil)
    drawer = self.get_drawer
    dt = drawer.transact(amount_cents, self, cash_register, tag, notes, order)
    return dt
  end
  
  private
  
  def generate_random_string
    collection = [('a'..'z'),('A'..'Z'),('0'..'9')].map{|i| i.to_a}.flatten
    (0...128).map{ collection[rand(collection.length)] }.join
  end

end
