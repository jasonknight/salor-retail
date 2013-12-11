class ItemStock < ActiveRecord::Base

  include SalorBase
  include SalorScope
  
  belongs_to :item
  belongs_to :vendor
  belongs_to :company
  belongs_to :location, :polymorphic => true
  has_many :stock_transactions, :as => :to
  
  def locationstring
    if self.new_record?
      ""
    else
      "#{ self.location.class.to_s }:#{ self.location.id if self.location }"
    end
  end
  
  def locationstring=(string)
    parts = string.split(":")
    self.location_type = parts[0]
    self.location_id = parts[1]
  end
  
  


  

  
  # this method moves min_quantity units from the StockLocation to the Location when the quantity is smaller than zero.
#   def location_quantity=(amnt)
#     log_action("called location_quantity with #{amnt}")
#     amnt = amnt.to_f
#     if amnt <= 0 and self.item and self.item.min_quantity and self.stock_location and self.stock_location_quantity > 0 then
#       log_action("Trying to update amounts")
#       if self.stock_location_quantity >= self.item.min_quantity then
#         log_action("StockLocation has more than Item.min_quantity. So we can will move min_quantity over to Location")
#         self.update_attribute :stock_location_quantity, self.stock_location_quantity - self.item.min_quantity
#         amnt = self.item.min_quantity
#       else
#         log_action("StockLocation is less than min_quantity, but we will take out everything.")
#         amnt = self.stock_location_quantity
#         self.update_attribute :stock_location_quantity, 0
#       end
#     end
#     log_action("Setting location_quantity to #{amnt}")
#     write_attribute :location_quantity, amnt
#   end
end
