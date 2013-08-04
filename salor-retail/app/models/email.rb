class Email < ActiveRecord::Base
  belongs_to :company
  belongs_to :vendor
  belongs_to :user
  belongs_to :model, :polymorphic => true
  
  validates_presence_of :vendor_id, :company_id
end
