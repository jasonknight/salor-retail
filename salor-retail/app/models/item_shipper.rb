class ItemShipper < ActiveRecord::Base
  include SalorScope
  
  belongs_to :shipper
  belongs_to :vendor
  belongs_to :company
  belongs_to :item
  
  before_save :set_item_sku
  before_update :set_item_sku
  
  def set_item_sku
    self.item_sku = self.item.sku if self.item
  end
end
