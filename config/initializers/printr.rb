Printr.setup do |config|
  config.printr_source = {:active_record => {
    :class_name => VendorPrinter,
    :name => :name,
    :path => :path
  }}
  #config.sanitize_tokens = ['$','\$']
  config.debug = false
  config.logger = File.open("/tmp/printr.txt",'a')
end
