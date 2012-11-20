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
  if SalorRetail::Application::SR_DEBIAN_SITEID != 'none'
    config.logger = File.open("/var/log/salor-retail/#{ SalorRetail::Application::SR_DEBIAN_SITEID}/printr.txt",'a')
  else
    config.logger = File.open(File.join(Rails.root,'log','printr.txt'),'a')
  end
end
