class ItemStock < ActiveRecord::Base
  belongs_to :item
  belongs_to :stock_location
  belongs_to :location
  attr_accessible :quantity, :location_quantity, :stock_location_quantity, :location_id, :stock_location_id
end
