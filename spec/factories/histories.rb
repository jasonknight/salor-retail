# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :history do
    url "MyString"
    owner_type "MyString"
    owner_id 1
    action_taken "MyString"
    model "MyString"
    model_id 1
    changes_made "MyText"
  end
end
