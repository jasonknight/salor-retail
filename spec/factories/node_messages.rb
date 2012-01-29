# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :node_message do
    source_sku "MyString"
    dest_sku "MyString"
    mdhash "MyString"
  end
end
