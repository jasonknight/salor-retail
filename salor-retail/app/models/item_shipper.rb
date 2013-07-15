class ItemShipper < ActiveRecord::Base
  belongs_to :shipper
  belongs_to :vendor
  belongs_to :company
  belongs_to :item
  
  attr_accessible :item_sku, :list_price, :purchase_price, :shipper_sku, :shipper_id,:item_id
  before_save :set_item_sku
  before_update :set_item_sku
  
  def set_item_sku
    self.item_sku = self.item.sku if self.item
  end
end
