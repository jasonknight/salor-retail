class MergeConfigurationIntoVendor < ActiveRecord::Migration
  def change
    add_column :vendors, :lp_per_dollar, :float
    add_column :vendors, :dollar_per_lp, :float
    add_column :vendors, :address, :text
    add_column :vendors, :telephone, :string
    add_column :vendors, :receipt_blurb, :text
    add_column :vendors, :pagination, :integer, :default => 10
    add_column :vendors, :stylesheets, :string
    add_column :vendors, :cash_drawer, :string
    add_column :vendors, :open_cash_drawer, :boolean
    add_column :vendors, :last_wholesaler_check, :datetime
    add_column :vendors, :csv_imports, :text
    add_column :vendors, :csv_imports_url, :string
    add_column :vendors, :items_view_list, :boolean
    add_column :vendors, :url, :string, :default => "http://default.sr.localhost"
    add_column :vendors, :salor_printer, :boolean
    add_column :vendors, :receipt_blurb_footer, :text
    add_column :vendors, :calculate_tax, :boolean
    add_column :vendors, :license_accepted, :boolean
    add_column :vendors, :csv_categories, :boolean
    add_column :vendors, :csv_buttons, :boolean
    add_column :vendors, :csv_discounts, :boolean
    add_column :vendors, :csv_customers, :boolean
    add_column :vendors, :csv_loyalty_cards, :boolean
    add_column :vendors, :invoice_blurb, :text
    add_column :vendors, :invoice_blurb_footer, :text
  end
end
