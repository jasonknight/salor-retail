# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :employee_login do
    login "2013-02-05 06:18:10"
    logout "2013-02-05 06:18:10"
    hourly_rate 1.5
    employee nil
    vendor nil
    shift_seconds 1
    amount_due 1.5
  end
end
