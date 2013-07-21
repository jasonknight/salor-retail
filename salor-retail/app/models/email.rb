class Email < ActiveRecord::Base
  belongs_to :company
  belongs_to :vendor
  belongs_to :user
  belongs_to :model, :polymorphic => true
end
