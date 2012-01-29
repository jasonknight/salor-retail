namespace :salor do
  task :test => [:environment] do
    require "#{RAILS_ROOT}/db/seeds_testing.rb"
  end
  task :test_discounts => [:environment] do 
    require "#{RAILS_ROOT}/test/setup.rb"
    if File.exists? "#{RAILS_ROOT}/test/unit/discount_setup.rb" then
      require "#{RAILS_ROOT}/test/unit/discount_setup.rb"
    end
    require "#{RAILS_ROOT}/test/unit/discount_test.rb"
  end
  task :test_gift_cards => [:environment] do 
    require "#{RAILS_ROOT}/test/setup.rb"
    if File.exists? "#{RAILS_ROOT}/test/unit/gift_card_setup.rb" then
      require "#{RAILS_ROOT}/test/unit/gift_card_setup.rb"
    end
    require "#{RAILS_ROOT}/test/unit/gift_card_test.rb"
  end
end
