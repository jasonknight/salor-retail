ActionMailer::Base.sendmail_settings = { :arguments => '-i' }

SalorRetail::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb
  
  config.action_mailer.delivery_method = :sendmail
  
  if SalorRetail::Application::CONFIGURATION[:exception_notification] == true
    require File.join(Rails.root, 'lib', 'exceptions.rb')
    sender_address = SalorRetail::Application::CONFIGURATION[:exception_notification_sender]
    exception_recipients = SalorRetail::Application::CONFIGURATION[:exception_notification_receipients]
    config.middleware.use ExceptionNotifier,
        :email_prefix => "[SalorRetailException] ",
        :sender_address => sender_address,
        :exception_recipients => exception_recipients,
        :sections => %w(salor request session environment backtrace)
  end
  
  if SalorRetail::Application::SR_DEBIAN_SITEID != 'none'
    ENV['SCHEMA'] = File.join('/', 'var', 'lib', 'salor-retail', SalorRetail::Application::SR_DEBIAN_SITEID, 'schema.rb')
    
    config.paths['log'] = ["/var/log/salor-retail/#{SalorRetail::Application::SR_DEBIAN_SITEID}/production.log"]
    
    config.paths['config/database'] = ["/etc/salor-retail/#{SalorRetail::Application::SR_DEBIAN_SITEID}/database.yml"]
    
    config.paths['tmp'] = ["/var/tmp/salor-retail/#{SalorRetail::Application::SR_DEBIAN_SITEID}"]
    
    # Use a different cache store in production
    config.cache_store = :file_store, File.join('/', 'var', 'cache', 'salor-retail', SalorRetail::Application::SR_DEBIAN_SITEID)
  end
  
  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = false

  # Disable Rails's static asset server (Apache or nginx will already do this)
  config.serve_static_assets = false

  # Compress JavaScripts and CSS
  config.assets.compress = true

  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = true

  # Generate digests for assets URLs
  config.assets.digest = true

  # Defaults to Rails.root.join("public/assets")
  # config.assets.manifest = YOUR_PATH

  # Specifies the header that your server uses for sending files
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Prepend all log lines with the following tags
  # config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  # Use a different cache store in production
  # config.cache_store = :file_store, File.join(Rails.root,"/tmp/cache")

  # Enable serving of images, stylesheets, and JavaScripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  # config.assets.precompile += %w( search.js )

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify
end
