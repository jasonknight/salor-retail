require 'rubygems'
require 'spork'
#uncomment the following line to use spork with the debugger
#require 'spork/ext/ruby-debug'

Spork.prefork do
  # Loading more in this block will cause your tests to run faster. However,
  # if you change any configuration or code from libraries loaded here, you'll
  # need to restart spork for it take effect.
  ENV["RAILS_ENV"] ||= 'test'
  require File.expand_path("../../config/environment", __FILE__)
  require 'rspec/rails'
  require 'rspec/autorun'
  
  # Requires supporting ruby files with custom matchers and macros, etc,
  # in spec/support/ and its subdirectories.
  Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}
  
  RSpec.configure do |config|
    # == Mock Framework
      #
      # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
      #
      # config.mock_with :mocha
      # config.mock_with :flexmock
      # config.mock_with :rr
      config.mock_with :rspec
  
      # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
      # config.fixture_path = "#{::Rails.root}/spec/fixtures"
  
      # If you're not using ActiveRecord, or you'd prefer not to run each of your
      # examples within a transaction, remove the following line or assign false
      # instead of true.
      # false carries over database records between specs
      config.use_transactional_fixtures = true
  
      # If true, the base class of anonymous controllers will be inferred
      # automatically. This will be the default behavior in future versions of
      # rspec-rails.
      config.infer_base_class_for_anonymous_controllers = false
  
      config.treat_symbols_as_metadata_keys_with_true_values = true
      config.filter_run :focus => true
      config.run_all_when_everything_filtered = true
  
  
      config.before(:suite) do
        DatabaseCleaner.strategy = :transaction
        DatabaseCleaner.clean_with(:truncation)
      end
  
      config.before(:each) do
        DatabaseCleaner.start
      end
  
      config.after(:each) do
        DatabaseCleaner.start
      end
    require 'rspec/mocks'
    require 'rspec/expectations'
    require 'rspec/matchers'
    require 'rack/handler/webrick'
    require 'capybara/rspec'
    require 'mechanize'
    require 'faker'
  end
end

Spork.each_run do
  # This code will be run each time you run your specs.

end

# --- Instructions ---
# Sort the contents of this file into a Spork.prefork and a Spork.each_run
# block.
#
# The Spork.prefork block is run only once when the spork server is started.
# You typically want to place most of your (slow) initializer code in here, in
# particular, require'ing any 3rd-party gems that you don't normally modify
# during development.
#
# The Spork.each_run block is run each time you run your specs.  In case you
# need to load files that tend to change during development, require them here.
# With Rails, your application modules are loaded automatically, so sometimes
# this block can remain empty.
#
# Note: You can modify files loaded *from* the Spork.each_run block without
# restarting the spork server.  However, this file itself will not be reloaded,
# so if you change any of the code inside the each_run block, you still need to
# restart the server.  In general, if you have non-trivial code in this file,
# it's advisable to move it into a separate file so you can easily edit it
# without restarting spork.  (For example, with RSpec, you could move
# non-trivial code into a file spec/support/my_helper.rb, making sure that the
# spec/support/* files are require'd from inside the each_run block.)
#
# Any code that is left outside the two blocks will be run during preforking
# *and* during each_run -- that's probably not what you want.
#
# These instructions should self-destruct in 10 seconds.  If they don't, feel
# free to delete them.




# This file is copied to spec/ when you run 'rails generate rspec:install'

# Helper Methods used in tests

def login_user(user)
  visit '/employees/login?code=31202053297'
end
def login_employee(code)
  GlobalData.salor_user = Employee.login(code)
  visit '/employees/login?code=' + code.to_s
end

def login_remote_user(user,server = 'salor.com')
  ohost = Capybara.default_host
  Capybara.default_host = server
  puts server + '/employees/login?code=' + user.username + "1234"
  visit server + '/employees/login?code=' + user.username + "1234"
  Capybara.default_host = ohost
end
def single_store_setup
    @user = Factory :user
    @vendor = Factory :vendor, :user => @user
    @manager = Factory :manager, :user => @user, :vendor => @vendor
    @cashier = Factory :cashier, :user => @user, :vendor => @vendor
    @cash_register = Factory :cash_register, :vendor => @vendor
    @tax_profile = Factory :tax_profile, :user => @user
    @category = Factory :category, :vendor => @vendor
    @order = Factory :order, :user => @user, :vendor => @vendor, :cash_register => @cash_register
    @item = Factory :item, :vendor => @vendor, :tax_profile => @tax_profile, :category => @category
    @item2 = Factory :item, :sku => "TEST2", :base_price => 29.95,:vendor => @vendor, :tax_profile => @tax_profile, :category => @category
    GlobalData.salor_user = @user
    GlobalData.vendor = @vendor
    GlobalData.vendor_id = @vendor.id
    GlobalData.salor_user.get_meta.update_attribute :vendor_id,@vendor.id
    GlobalData.conf = @vendor.salor_configuration
    $Conf = @vendor.salor_configuration
    $User = @user 

    @enter_event = 'e = jQuery.Event("keypress");e.which = 13;e.keyCode = 13;$("INPUT").trigger(e);';
end
def multi_store_setup
  @user = Factory :user
  $User = @user
  @vendor = Factory :vendor, :name => "Vendor One",:user => @user
  @vendor2 = Factory :vendor, :name => "Vendor Two", :user => @user
  @cash_register = Factory :cash_register, :vendor => @vendor
  @tax_profile = Factory :tax_profile, :user => @user
  @category = Factory :category, :vendor => @vendor
  GlobalData.salor_user = @user
  GlobalData.vendor = @vendor
  GlobalData.vendor_id = @vendor.id
end
