class Company < ActiveRecord::Base
  include SalorScope
  
  has_many :vendors
  has_many :customers
end
