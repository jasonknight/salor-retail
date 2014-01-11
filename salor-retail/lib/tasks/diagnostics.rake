namespace :salor do
  task :diagnostics => [:environment] do
    body = ''
    Vendor.visible.each do |v|
      puts "\n\nRunning diagnostics for vendor #{ v.name }. Please wait for the result ..."
      d = v.run_diagnostics
      puts "\n=================== DIAGNOSTICS RESULT BEGIN ================="
      if d[:status] != true
        puts d.inspect
        puts "\n\nSending report to #{ v.technician_email.inspect } ..."
        UserMailer.technician_message(v, "Diagnostics report", d[:result].inspect, nil).deliver
      else
        puts "All is OK"
      end
      puts "\n=================== DIAGNOSTICS RESULT END =================\n\n"
    end
  end
end