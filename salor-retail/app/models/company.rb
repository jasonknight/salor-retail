class Company < ActiveRecord::Base
  attr_accessible :active, :auth, :auth_https_mode, :auth_user, :domain, :email, :full_subdomain, :full_url, :hidden, :hidden_at, :hidden_by, :https, :identifier, :mode, :name, :removal_pending, :subdomain, :virtualhost_filter
  
  has_many :vendors
end
