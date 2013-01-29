# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :item_stock_adjustment do
    location nil
    item nil
    order_item nil
    employee nil
    order nil
    shipment nil
    shipment_item nil
    stock_location nil
    quantity 1.5
    item_stock nil
    vendor nil
  end
end
