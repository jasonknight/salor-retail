namespace :salor do
  task :seed => [:environment] do
    system("rake db:drop")
    system("rake db:create")
    system("rake db:migrate")
    system("rake db:seed --trace")
  end
  task :refresh => [:environment] do
    require "#{Rails.root}/db/seeds_testing.rb"
  end
  task :update => [:environment] do
    require "#{Rails.root}/db/update_seeds.rb"
  end
  task :upgrade => [:environment] do
    require "#{Rails.root}/db/update_seeds.rb"
  end
  task :barcode => [:environment] do
    require "#{Rails.root}/db/barcode_sheet.rb"
  end
  task :bigtest => [:environment] do
    require "#{Rails.root}/db/seeds_bigtest.rb"
  end
end
