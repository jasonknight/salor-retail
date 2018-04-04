namespace :salor do
  task :test => [:environment] do
    require "#{Rails.root.to_s}/db/seeds_testing.rb"
  end
  task :test_discounts => [:environment] do 
    require "#{Rails.root.to_s}/test/setup.rb"
    if File.exists? "#{Rails.root.to_s}/test/unit/discount_setup.rb" then
      require "#{Rails.root.to_s}/test/unit/discount_setup.rb"
    end
    require "#{Rails.root.to_s}/test/unit/discount_test.rb"
  end
  task :test_gift_cards => [:environment] do 
    require "#{Rails.root.to_s}/test/setup.rb"
    if File.exists? "#{Rails.root.to_s}/test/unit/gift_card_setup.rb" then
      require "#{Rails.root.to_s}/test/unit/gift_card_setup.rb"
    end
    require "#{Rails.root.to_s}/test/unit/gift_card_test.rb"
  end
end
