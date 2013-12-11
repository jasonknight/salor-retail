class AddQuoteFieldsToVendors < ActiveRecord::Migration
  def change
    begin
      add_column :vendors, :use_quote_numbers, :boolean, :default => true
      add_column :vendors, :unused_quote_numbers, :string, :default => "--- []\n"
      add_column :vendors, :largest_quote_number, :integer, :default => 0
      add_column :orders,:qnr,:integer,:default => 0
    rescue
      puts $!
    end
  end
end
