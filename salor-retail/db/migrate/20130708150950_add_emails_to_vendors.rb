class AddEmailsToVendors < ActiveRecord::Migration
  def change
    add_column :vendors, :enable_technician_emails, :boolean
    add_column :vendors, :technician_email, :string
  end
end
