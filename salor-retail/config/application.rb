# coding: utf-8

# Copyright (c) 2012 Red (E) Tools Ltd.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require File.expand_path('../boot', __FILE__)

require 'rails/all'

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups(:assets => %w(development test)))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

module SalorRetail
  
  mattr_accessor :tailor
  mattr_accessor :old_tailors
  mattr_accessor :requestcount
  
  @@tailor = nil
  @@old_tailors = []
  @@requestcount = 0
  
  class Application < Rails::Application
    
    if ENV['SR_DEBIAN_SITEID']
      SR_DEBIAN_SITEID = ENV['SR_DEBIAN_SITEID']
    else
      SR_DEBIAN_SITEID = 'none'
    end
    
    puts "Using database set by environment variable SR_DEBIAN_SITEID (#{SR_DEBIAN_SITEID})"
    
    if File.exists?(File.join(Rails.root, '..', 'debian', 'changelog'))
      changelog = File.open(File.join(Rails.root, '..', 'debian', 'changelog'), 'r').read.split("\n")[0]
      VERSION = "Version " + /.*\((.*)\).*/.match(changelog)[1]
    end
    VERSION ||= `dpkg -s salor-retail | grep Version`
    
    if File.exists?(File.join('/', 'etc','salor-retail', SR_DEBIAN_SITEID, 'config.yml'))
      CONFIGURATION = YAML::load(File.open(File.join('/', 'etc','salor-retail', SR_DEBIAN_SITEID, 'config.yml'), 'r').read)
    else
      CONFIGURATION = YAML::load(File.open(File.join(Rails.root, 'config', 'config.yml'), 'r').read)
    end
    
    LANGUAGES = { 'en' => 'English', 'gn' => 'Deutsch', 'fr' => 'Français', 'es' => 'Español', 'el' => 'Greek', 'ru' => 'Русский', 'it' => 'Italiana', 'cn' => 'Chinese', 'hr' => 'Hrvatska','fi' => 'Suomi', 'nl' => 'Dutch' }
    COUNTRIES = { 'cc' => :default, 'us' => 'USA', 'gb' => 'England', 'ca' => 'Canada', 'de' => 'Deutschland', 'at' => 'Österreich', 'fr' => 'France', 'es' => 'España', 'el' => 'Ελλάδα', 'ru' => 'Россия', :it => 'Italia', 'cn' => '中国', 'hr' => 'Hrvatska','fi' => 'Suomi', 'nl' => 'Nederland' }
    COUNTRIES_REGIONS = { 'cc' => 'en-us', 'us' => 'en-us', 'gb' => 'en-gb', 'ca' => 'en-ca', 'de' => 'gn-de', 'at' => 'gn-de', 'fr' => 'fr-fr', 'es' => 'es-es', 'el' => 'el-el', 'ru' => 'ru-ru', 'it' => 'it-it', 'cn' => 'cn-cn', 'hr' => 'hr-hr' ,'fi' => 'fi-fi', 'nl' => 'nl-nl'}
    COUNTRIES_INVOICES = { 'cc' => 'cc', 'us' => 'cc', 'gb' => 'cc', 'ca' => 'ca', 'de' => 'cc', 'at' => 'cc', 'fr' => 'cc', 'es' => 'cc', 'el' => 'cc', 'ru' => 'cc', 'it' => 'cc', 'cn' => 'cc', 'hr' => 'cc','fi' => 'cc', 'nl' => 'cc' }
    CURRENCIES = ["USD", "EUR", "CHF", "CAD"]
    
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    config.active_record.observers = :history_observer
    
    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Vienna'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    #config.i18n.load_path += Dir[Rails.root.join('roles', '*.{rb,yml}').to_s]
    config.i18n.default_locale = 'en'

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    # config.active_record.schema_format = :sql

    # Enforce whitelist mode for mass assignment.
    # This will create an empty whitelist of attributes available for mass-assignment for all models
    # in your app. As such, your models will need to explicitly whitelist or blacklist accessible
    # parameters by using an attr_accessible or attr_protected declaration.
     config.active_record.whitelist_attributes = false

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'
  end
end
