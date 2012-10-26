class ActiveRecord::Base
    mattr_accessor :shared_connection
    @@shared_connection = nil

    def self.connection
      @@shared_connection ||= retrieve_connection
      @@shared_connection
    end
  end
  puts "Shared connection loaded"
