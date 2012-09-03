class AddSensibleDefaultsToTables < ActiveRecord::Migration
  def change
    begin
      change_column_default :cash_registers, :salor_printer, true
      change_column_default :cash_registers, :thermal_printer, '/dev/usb/lp0'
      change_column_default :cash_registers, :sticker_printer, '/dev/usb/lp1'
      add_column :vendors,:token,:string
    rescue
      puts "Migration Error: " + $!.to_s
    end
    Vendor.all.each do |v|
      v.update_attribute :token, v.name.gsub(/[^\w]/,'_') + rand(99999).to_s
    end
  end
end
