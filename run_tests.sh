export RAILS_ENV=test
bundle exec rake db:migrate
bundle exec guard
