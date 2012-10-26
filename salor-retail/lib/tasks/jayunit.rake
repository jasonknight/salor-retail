# Move this file ::Rails.root/lib/tasks
namespace :jay_unit do
  task :run => [:environment] do
    JayUnit.run ENV['test']
  end
end
