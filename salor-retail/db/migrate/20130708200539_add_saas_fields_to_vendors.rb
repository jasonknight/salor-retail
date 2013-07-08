class AddSaasFieldsToVendors < ActiveRecord::Migration
  def change
    add_column :vendors, :identifier, :string
    add_column :vendors, :full_subdomain, :string
    add_column :vendors, :full_url, :string
    add_column :vendors, :virtualhost_filter, :string
    add_column :vendors, :auth_https_mode, :integer
    add_column :vendors, :https, :boolean
    add_column :vendors, :auth, :boolean
    add_column :vendors, :domain, :string
    add_column :vendors, :subdomain, :string
  end
end
