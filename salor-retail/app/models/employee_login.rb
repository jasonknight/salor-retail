class EmployeeLogin < ActiveRecord::Base
  belongs_to :employee
  belongs_to :vendor
  before_save :set_totals
  before_update :set_totals
  attr_accessible :amount_due, :hourly_rate, :login, :logout, :shift_seconds, :employee_id,:vendor_id
  def set_totals
    if self.logout then
      self.shift_seconds = (self.logout - self.login).to_i
    end
    if self.shift_seconds and self.hourly_rate then
      hours = (self.shift_seconds.to_f / 60 / 60)
      self.amount_due = hours * self.hourly_rate
    end
  end
end
