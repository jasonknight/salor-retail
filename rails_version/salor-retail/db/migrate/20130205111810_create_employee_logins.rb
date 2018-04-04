class CreateEmployeeLogins < ActiveRecord::Migration
  def change
    begin
      create_table :employee_logins do |t|
        t.datetime :login
        t.datetime :logout
        t.float :hourly_rate
        t.references :employee
        t.references :vendor
        t.integer :shift_seconds
        t.float :amount_due

        t.timestamps
      end
      add_index :employee_logins, :employee_id
      add_index :employee_logins, :vendor_id
    rescue
      puts $!.inspect
    end
  end
end
