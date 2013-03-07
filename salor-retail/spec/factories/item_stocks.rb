# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :item_stock do
    item nil
    stock_location nil
    quantity 1.5
    location nil
  end
end
