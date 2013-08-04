require 'fileutils'
class Plugin < ActiveRecord::Base
  include SalorScope
  include SalorBase
  
  belongs_to :company
  belongs_to :vendor
  
  validates_presence_of :vendor_id, :company_id

  mount_uploader :filename, PluginUploader # see app/uploaders This is done with CarrierWave
end
