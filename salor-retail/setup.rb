#!/usr/bin/env ruby
require 'yaml'
def show_head()
	puts "*" * 69
	[
		"Welcome to the Salor Retail Installer(SRI)."
	].each do |l|
		puts "* %-65s *" % l
	end
	puts "*" * 69
end	
def show_help()
	puts "*" * 69
	[
		"Salor Retail Installer(SRI) Help",
		"You can use the commands: ",
		("    %-15s: %s" % ["install", "will run bundle install, and rake tasks"]),
		("    %-15s: %s" % ["exit", "exit the program"]),
	].each do |l|
		puts "* %-65s *" % l
	end
	puts "*" * 69
end
def pretty_print_hash(h, t='Hash')
	print("\n")
	puts "*" * 45
	puts "* %41s *" % t
	puts "*" * 45
	h.each do |k,v|
		puts "*%10s : %-30s*" % [k,v]
	end
	puts "*" * 45
end	
def get_yono() 
	while true
		print "\nIs this correct[y]: "
		yono = gets.strip
		if (yono == 'y') then
			return true
		elsif yono == 'n' then
			return false
		else
			puts "Only y or n accepted"
		end
	end
end
def collect_mysql_info()
	print "\nMysql User: "
	user = gets.strip
	print "\nMysql Pass: "
	pass = gets.strip
	print "\nMysql Host[localhost]: "
	host = gets.strip
	host = 'localhost' if host.length < 1
	print "\nMysql Database[sr]:"
	db = gets.strip
	db = 'sr' if db.length < 1
	settings = { :username => user, :password => pass, :host => host, :database => db }
	pretty_print_hash(settings,"Your MySQL Settings")
	
	if get_yono() then
		return settings
	else
		return collect_mysql_info()
	end

end
def run_database_install()
	mysql_settings = collect_mysql_info()
	db_yml = YAML.load_file('config/database.yml.default')
	["development","test","production"].each do |section|
		mysql_settings.each do |k,v|
			if k == :database then
				v = "#{v}_#{section}"
			end
			db_yml[section][k.to_s] = v
		end
	end	
	puts "Writing database.yml"
	File.open('config/database.yml', 'w') {|f| f.write db_yml.to_yaml }
	puts "Creating Database"
	`rake db:create`
	puts "Migrating the databse, this could take awhile, go get some tea, or coffee, or your favorite beverage...really, it takes awhile."
	`rake db:migrate`
end
def run_seed()
	`rake db:seed`
end
def run_install()
	`bundle install`
	run_database_install()
	run_seed()
	puts "Install Complete!"
end

show_head();

while true do
	print "\nCommand: > "
	s = gets.strip
	if ( s == 'help' ) then
		show_help()
	elsif s == 'exit' then
		exit
	elsif s == 'install' then
		run_install()
	elsif s == 'database' then
		run_database_install()
	elsif s == 'seed' then
		run_seed()
	end	
end