# A sample Guardfile
# More info at https://github.com/guard/guard#readme

# these will restart spork server
guard 'spork', :cucumber_env => { 'RAILS_ENV' => 'test' }, :rspec_env => { 'RAILS_ENV' => 'test' } do
  watch('config/application.rb')
  watch('config/environment.rb')
  watch(%r{^config/environments/.+\.rb$})
  watch(%r{^config/initializers/.+\.rb$})
  watch('config/routes.rb')
  watch('Gemfile')
  watch('Gemfile.lock')
  watch('spec/spec_helper.rb') { :rspec }
  watch(%r{features/support/}) { :cucumber }
  watch(%r{^spec/support/.+\.rb$})
end

# these will just re-run the tests
guard 'rspec', :version => 2, :cli => "--drb --debug --format documentation", :all_on_start => false, :all_after_pass => false do
  #watch(%r{^spec/.+_spec\.rb$})                       { |m| "spec/#{m[1]}.rb" }
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec" }

  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^app/(.+)\.rb$})                           { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r{^app/(.*)(\.erb|\.haml)$})                 { |m| "spec/#{m[1]}#{m[2]}_spec.rb" }
  watch(%r{^lib/(.+)\.rb$})                           { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch(%r{^app/controllers/(.+)_(controller)\.rb$})  { |m| ["spec/routing/#{m[1]}_routing_spec.rb", "spec/#{m[2]}s/#{m[1]}_#{m[2]}_spec.rb", "spec/acceptance/#{m[1]}_spec.rb"] }
  watch(%r{^app/models/.+\.rb$})
  watch(%r{^spec/support/(.+)\.rb$})                  { "spec" }
  watch('config/routes.rb')                           { "spec/routing" }
  watch('app/controllers/application_controller.rb')  { "spec/controllers" }
  watch(%r{^app/views/(.+)/(.+)\.html.*$})          { |m| "spec/requests/#{m[2]}_spec.rb" }
  watch(%r{^spec/factories/.+\.rb$})                  { "spec" }
  watch(%r{^spec/requests/(.+)\.rb$})                 { |m| "spec/requests/#{m[1]}.rb" }
  watch(%r{^config/locales/.+\.yml$})                 { "spec" }
end
