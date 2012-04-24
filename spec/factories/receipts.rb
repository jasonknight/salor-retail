# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :receipt do
    ip "MyString"
    employee_id 1
    content "MyText"
  end
end
