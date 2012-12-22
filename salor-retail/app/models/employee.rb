# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

require 'digest/sha2'
class Employee < ActiveRecord::Base
  # {START}
	include SalorScope
	include SalorBase
  include SalorModel
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  include UserEmployeeMethods
  
  validate :validify
  belongs_to :user
  belongs_to :vendor
  has_many :orders
  has_many :order_items
  has_many :receipts
  has_many :vendors, :through => :user
  has_many :paylife_structs, :as => :owner
  has_many :cash_register_dailies
  has_and_belongs_to_many :roles
  has_one :meta, :as => :ownable
  has_one :drawer, :as => :owner
  has_many :drawer_transactions, :as => :owner
  has_many :histories, :as => :owner
  # Setup accessible (or protected) attributes for your model
  attr_accessible :uses_drawer_id,:apitoken,:js_keyboard,:role_ids,:language,:vendor_id,:user_id,:first_name,:last_name,:username, :email, :password, :password_confirmation, :remember_me
  attr_accessible :auth_code
  
  # Trying to define the generate_password in user_employee methods was throwing errors.
  def self.generate_password(string)
    return Digest::SHA2.hexdigest("#{string}")
  end
  def self.find_for_authentication(conditions={})
    conditions[:hidden] = false
      find(:first, :conditions => conditions)
    end 
  def validify
    if self.email.blank? then
      e = Digest::SHA256.hexdigest(Time.now.to_s)[0..12]
      self.email = "#{e}@salorpos.com"
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
  # {END}
end
