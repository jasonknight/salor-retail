require 'mechanize'
server = "http://salor.com";
@agent = Mechanize.new
@agent.get(server + "/employees/login?code=admin1234") do |p|
	puts p.parser.xpath("//text()").to_s
end
