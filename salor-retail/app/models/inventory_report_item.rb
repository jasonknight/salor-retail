class InventoryReportItem < ActiveRecord::Base
  belongs_to :inventory_report
  belongs_to :item
  attr_accessible :item_quantity, :real_quantity, :vendor_id
  def restore
    self.item.update_attributes(:real_quantity => self.real_quantity, :quantity => self.item_quantity, :real_quantity_updated => true)
  end
end
