class History < ActiveRecord::Base
  belongs_to :owner, :polymorphic => true
  belongs_to :model, :polymorphic => true
  include SalorBase
  include SalorModel
  include SalorScope
  before_create :set_fields
  def set_fields
    if self.owner_id.nil? then
      self.owner = $User
    end
    self.url = $Request.url
    self.params = $Params.to_json
    self.ip = $Request.ip
  end
  def self.record(action,object,sen=5)
    # sensitivity is from 5 (least sensitive) to 1 (most sensitive)
    h = History.new
    h.sensitivity = sen
    h.model = object if object
    h.action_taken = action
    if object and object.respond_to? :changes then
      h.changes_made = object.changes.to_json
    end
    h.save
  end
end
