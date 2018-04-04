class ChangeVendorCountryDefault < ActiveRecord::Migration
  def up
    change_column_default :vendors, :country, 'us'
    change_column_default :vendors, :currency, 'USD'
  end

  def down
  end
end
