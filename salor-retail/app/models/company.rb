class Company < ActiveRecord::Base  
  has_many :vendors
  has_many :customers
end
