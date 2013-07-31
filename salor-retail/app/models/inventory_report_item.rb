class InventoryReportItem < ActiveRecord::Base
  belongs_to :inventory_report
  belongs_to :item
  belongs_to :vendor
  belongs_to :company
  
  monetize :price_cents
  monetize :purchase_price_cents
  
  def restore
    self.item.update_attributes(:real_quantity => self.real_quantity, :quantity => self.item_quantity, :real_quantity_updated => true)
  end
end
