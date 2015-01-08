class InventoryReport < ActiveRecord::Base
  include SalorScope
  include SalorBase
  
  belongs_to :vendor
  belongs_to :company
  has_many :inventory_report_items
  
  validates_presence_of :vendor_id, :company_id
  
  def hide(by)
    self.hidden = true
    self.hidden_at = Time.now
    self.hidden_by = by
    self.save!
  end
  
end
