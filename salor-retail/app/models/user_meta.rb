class UserMeta < ActiveRecord::Base
  belongs_to :user
  belongs_to :company
  attr_accessible :key, :value
  
  validates_presence_of :company_id
end
