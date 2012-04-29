require 'net/http'
uri = URI("http://service.red-e.eu/files/get_translations?file_id=12&p=#{ `hostid` } ")
Net::HTTP.get(uri)
