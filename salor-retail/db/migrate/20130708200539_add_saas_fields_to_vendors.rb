class AddSaasFieldsToVendors < ActiveRecord::Migration
  def change
    attrs = [
      :identifier, :string,
      :full_subdomain, :string,
      :full_url, :string,
      :virtualhost_filter, :string,
      :auth_https_mode, :integer,
      :https, :boolean,
      :auth, :boolean,
      :domain, :string,
      :subdomain, :string
    ]
    i = 0
    begin
      begin
        add_column :vendors, attrs[i], attrs[i +1]
      rescue
        puts $!
      end
      i += 2
    end while i < attrs.length
    
      # add_column :vendors, :identifier, :string
      # add_column :vendors, :full_subdomain, :string
      # add_column :vendors, :full_url, :string
      # add_column :vendors, :virtualhost_filter, :string
      # add_column :vendors, :auth_https_mode, :integer
      # add_column :vendors, :https, :boolean
      # add_column :vendors, :auth, :boolean
      # add_column :vendors, :domain, :string
      # add_column :vendors, :subdomain, :string
    
    
    Vendor.reset_column_information
    Vendor.all.each do |v|
      v.identifier = v.name.to_s.gsub(' ', '') unless v.identifier
      v.set_hash_id
    end
  end
end
