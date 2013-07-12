class Company < ActiveRecord::Base
  include SalorScope
  
  has_many :vendors
  has_many :customers
  has_many :users
  has_many :user_logins
  has_many :loyalty_cards
  
  def login(code)
    encrypted_password = Digest::SHA2.hexdigest("#{ code }")
    user = self.users.visible.where( :encrypted_password => encrypted_password ).first
    return user
  end
end
