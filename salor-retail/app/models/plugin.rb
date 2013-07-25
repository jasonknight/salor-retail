require 'fileutils'
class Plugin < ActiveRecord::Base
  include SalorScope
  include SalorBase
  belongs_to :company
  belongs_to :vendor
  attr_accessible :base_path, :filename, :hidden, :hidden_at, :hidden_by, :name
  mount_uploader :filename, PluginUploader # see app/uploaders This is done with CarrierWave
end
