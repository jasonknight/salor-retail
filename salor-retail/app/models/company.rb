class Company < ActiveRecord::Base
  include SalorScope
  
  has_many :vendors
  has_many :customers
  has_many :users
  has_many :user_logins
  has_many :loyalty_cards
  
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
  
  has_many :cash_registers
  has_many :orders
  has_many :categories
  has_many :items
  has_many :locations
  has_many :customers
  has_many :broken_items
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
  
  def login(code)
    encrypted_password = Digest::SHA2.hexdigest("#{ code }")
    user = self.users.visible.where( :encrypted_password => encrypted_password ).first
    return user
  end
end
