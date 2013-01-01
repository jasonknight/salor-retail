# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :inventory_report_item do
    inventory_report nil
    item nil
    real_quantity 1.5
    item_quantity 1.5
  end
end
