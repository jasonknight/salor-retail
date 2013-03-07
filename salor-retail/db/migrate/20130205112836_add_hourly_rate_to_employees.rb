class AddHourlyRateToEmployees < ActiveRecord::Migration
  def change
    add_column :employees, :hourly_rate, :float
  end
end
