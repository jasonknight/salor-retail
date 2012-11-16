# coding: UTF-8
require "#{Rails.root}/lib/printr"

Printr.setup do |config|
  config.printr_source = {:active_record => {
    :class_name => VendorPrinter,
    :name => :name,
    :path => :path
  }}
  #config.sanitize_tokens = ['$','\$']
  config.debug = false
  #config.sanitize = true
  config.encoding = 'ISO-8859-15'
  begin
    config.logger = File.open("log/printr.txt",'a')
  rescue Errno::ENOENT
    config.logger = File.open("log/printr.txt",'w+')
  end
end
