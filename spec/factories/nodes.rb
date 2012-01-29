# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :node do
    name "Master"
    sku "MASTER"
    token "MASTER"
    node_type "Both"
    url "google.com"
    is_self false
    accepted_ips "MyText"
    association :vendor
  end
end
