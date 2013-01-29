# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :item_shipper do
    shipper nil
    item nil
    purchase_price 1.5
    list_price 1.5
    item_sku "MyString"
    shipper_sku "MyString"
  end
end
