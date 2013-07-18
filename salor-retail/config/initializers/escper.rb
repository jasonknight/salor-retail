Escper.setup do |config|
  if SalorRetail::Application::SR_DEBIAN_SITEID != 'none'
    config.codepage_file = File.join('/', 'etc', 'salor-retail', SalorRetail::Application::SR_DEBIAN_SITEID, 'codepages.yml')
  else
    config.codepage_file = File.join(Rails.root, 'config', 'codepages.yml')
  end
  
  config.use_safe_device_path = SalorRetail::Application::CONFIGURATION[:use_safe_device_path] == true ? true : false
  
  if SalorRetail::Application::SR_DEBIAN_SITEID != 'none'
    config.safe_device_path = File.join('/', 'var', 'lib', 'salor-retail', SalorRetail::Application::SR_DEBIAN_SITEID, 'public', 'uploads')
  end
end