class InventoryReport < ActiveRecord::Base
  attr_accessible :name,:created_at,:updated_at, :vendor_id
  has_many :inventory_report_items
end
