namespace :salor do
  task :shippers_import => [:environment] do
    body = ''
    Vendor.visible.each do |v|
      puts "\n\nRunning shipper import for vendor #{ v.name }. Please wait ..."
      v.shippers.visible.each do |s|
        next if s.csv_url.blank?
        begin
          uploader = s.fetch_and_import_csv
          body += "<h1>#{s.name} for #{s.vendor.name} </h1>"
          body += "<ul>\n"
          uploader.messages.each do |m|
            body += "<li>#{m}</li>\n"
          end
          body += "</ul>\n"
        rescue => e
          body += "<h1>Error for: #{s.id} of vendor #{s.vendor_id}</h1>"
          body += "<p>#{e.message}</p>"
          body += "<ul>"
          e.backtrace.each do |b|
            body += "<li>#{b.inspect}</li>\n"
          end
          body += "</ul>"
        end
      end
      UserMailer.technician_message(v, "Shippers Import Report", body, nil).deliver
    end
  end
end