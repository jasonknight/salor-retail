class AddTimeZoneToVendors < ActiveRecord::Migration
  def change
    add_column :vendors, :time_zone, :string
  end
end
