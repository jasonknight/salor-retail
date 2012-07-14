require 'rubygems'
require 'json'
require 'yaml'
APP_PATH = File.expand_path('../../config/application',  __FILE__)
require File.expand_path('../../config/boot',  __FILE__)
require APP_PATH
require File.expand_path('../../config/environment',  __FILE__)

DIR_ROOT = Rails.root.to_s
YAML_ROOT = File.join(DIR_ROOT, 'config/locales')
JS_ROOT = File.join(DIR_ROOT, 'app/assets/javascripts', 'locales')

# locale javascript namespace
JS_NAMESPACE = 'i18n = '

Dir[File.join(YAML_ROOT, 'salor*.yml')].sort.each { |locale| 
  locale_yml = YAML::load(IO.read(locale))
  puts 'Filename: ' + locale
 # puts 'Filename JSON: ' + locale_yml.to_json
  File.open(
    File.join(JS_ROOT, File.basename(locale, '.*') + '.js'), 'w') { |f| 
     puts "Basename: " + File.basename(locale, '.*')
     l = File.basename(locale, '.*').split('.').last
    f.write(JS_NAMESPACE + locale_yml[l].to_json)
  }
}