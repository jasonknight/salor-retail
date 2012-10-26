# This script is to be run on software update, when you need to alter the
# database to make previous objects sane for the updated environment.
begin
  puts "Updating default roles ... "
  [ :manager, :head_cashier, :cashier, :stockboy,:edit_others_orders].each do |r|
    role = Role.find_or_create_by_name(r.to_s)
    role.save if role.new_record?
  end
  [ :orders,:items,:categories, 
    :locations,:shippers,:shipments, 
    :vendors, :employees, :discounts,:tax_profiles,:customers].each do |r|
    [:index,:edit,:destroy,:create,:update,:show].each do |a|
      role = Role.find_or_create_by_name(a.to_s + '_' + r.to_s)
      role.save if role.new_record?
    end
    role = Role.find_or_create_by_name('any_' + r.to_s)
    role.save if role.new_record?
  end
  puts "Updating default roles done."
rescue
  puts "Failed to update Roles."
  puts $!.backtrace
end

#make sure database.yml is correct

begin
  conf = YAML::load_file(RAILS_ROOT + '/config/database.yml')
	puts conf.inspect
  ["development","test","production"].each do |env|
    conf[env]["adapter"] = "mysql2"
  end
  File.open("#{RAILS_ROOT}/config/database.yml", 'w') { |f| YAML.dump(conf, f) }
rescue
  puts "Failed: " + $!.message
end


