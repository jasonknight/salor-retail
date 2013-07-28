class InventoryReport < ActiveRecord::Base
  include SalorScope
  include SalorBase
  
  belongs_to :vendor
  belongs_to :company
  has_many :inventory_report_items
  
  
end
