class StockTransaction < ActiveRecord::Base
  belongs_to :company
  belongs_to :vendor
  belongs_to :order
  belongs_to :user
  belongs_to :from, :polymorphic => true
  belongs_to :to, :polymorphic => true
  
  validates_presence_of :vendor_id
  validates_presence_of :company_id
  
  
end
