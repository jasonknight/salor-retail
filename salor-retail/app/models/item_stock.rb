class ItemStock < ActiveRecord::Base
  include SalorModel
  include SalorBase
  belongs_to :item
  belongs_to :stock_location
  belongs_to :location
  belongs_to :vendor
  attr_accessible :quantity, :location_quantity, :stock_location_quantity, :location_id, :stock_location_id
  before_create :set_model_user
  def location_quantity=(amnt)
    log_action("ItemStock.location_quantity #{amnt}")
    amnt = amnt.to_f
    if amnt <= 0 and self.item and self.item.min_quantity and self.stock_location and self.stock_location_quantity > 0 then
      log_action("Trying to update amounts")
      if self.stock_location_quantity >= self.item.min_quantity then
        log_action("stlqty > mqty")
        self.update_attribute :stock_location_quantity, self.stock_location_quantity - self.item.min_quantity
        amnt = self.item.min_quantity
      else
        log_action("slty < mqty")
        amnt = self.stock_location_quantity
        self.update_attribute :stock_location_quantity, 0
      end
    else 
      log_action("Failed to identify stock_location")
    end
    log_action("amnt is #{amnt}")
    write_attribute :location_quantity,amnt
  end
end
