class UserLogin < ActiveRecord::Base
  include SalorBase
  include SalorScope
  belongs_to :user
  belongs_to :vendor
  belongs_to :company
  before_save :set_totals
  before_update :set_totals
  attr_accessible :amount_due, :hourly_rate, :login, :logout, :shift_seconds, :user_id,:vendor_id
  DATE_PATTERN = /(\d{4,4})\/(\d{2,2})\/(\d{2,2}) (\d{2,2}):(\d{2,2}):(\d{2,2})/
  def set_totals
    if self.logout then
      self.shift_seconds = (read_attribute(:logout) - read_attribute(:login)).to_i
    end
    if self.shift_seconds and self.hourly_rate then
      hours = (self.shift_seconds.to_f / 60 / 60)
      self.amount_due = hours * self.hourly_rate
    end
  end
  def login=(d)
    if d.class == String
      puts "Class is string"
      #parts = d.scan(DATE_PATTERN)
      t = DateTime.parse(d)
      puts t
      write_attribute :login, t
    else
      write_attribute :login,d
    end
  end
  def login
    return self.login_before_type_cast
  end
  def logout=(d)
    if d.class == String
      parts = d.scan(DATE_PATTERN)
      t = DateTime.parse(d)
      write_attribute :logout, t
    else
      write_attribute :logout,d
    end
  end
  def logout
    return self.logout_before_type_cast
  end
end
