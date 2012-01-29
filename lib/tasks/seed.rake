namespace :salor do
  task :seed => [:environment] do
    system("rake db:drop")
    system("rake db:create")
    system("rake db:migrate")
    system("rake db:seed --trace")
  end
  task :refresh => [:environment] do
    require "#{RAILS_ROOT}/db/seeds_testing.rb"
  end
  task :update => [:environment] do
    require "#{RAILS_ROOT}/db/update_seeds.rb"
  end
  task :upgrade => [:environment] do
    require "#{RAILS_ROOT}/db/update_seeds.rb"
  end
  task :barcode => [:environment] do
    require "#{RAILS_ROOT}/db/barcode_sheet.rb"
  end
end
