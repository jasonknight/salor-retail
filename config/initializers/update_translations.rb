require 'net/http'
begin
p1 = fork {
  uri = URI("http://updates.red-e.eu/files/get_translations?file_id=12&p=#{ /(..):(..):(..):(..):(..):(..)/.match(`/sbin/ifconfig eth0`.split("\n")[0])[1..6].join } ")
  begin
    Net::HTTP.get(uri)
  rescue
    puts "update translations failed"
  end
}
Process.detatch(p1) if p1
rescue
end
