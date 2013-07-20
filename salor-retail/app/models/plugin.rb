require 'fileutils'
class Plugin < ActiveRecord::Base
  include SalorScope
  include SalorBase

  belongs_to :company
  belongs_to :vendor
  attr_accessible :base_path, :filename, :hidden, :hidden_at, :hidden_by, :name

  def filename=(uploaded_io)
    if (Rails.env == 'development') then
      path = "#{Rails.root}/lib/plugins"
    else
      path = File.join($DIRS[:uploads],"plugins")
    end
    FileUtils.mkdir_p path
    if ( ! File.exists?(path)) then
      raise "Plugins Directory Does Not Exist"
    end
  end

end
