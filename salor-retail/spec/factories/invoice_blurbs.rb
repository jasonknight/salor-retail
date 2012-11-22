# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :invoice_blurb do
    lang "MyString"
    body "MyText"
    is_header false
  end
end
