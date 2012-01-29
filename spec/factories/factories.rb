FactoryGirl.define do
  factory :user do
    username 'admin'
    email "salor@salorpos.com"
    password "31202053297"
    after_create do |u|
      u.meta = Factory :meta, :ownable_id => u.id
      u.save
    end
  end
  factory :user2, :class => User do
    username 'admin2'
    email "salor2@salorpos.com"
    password "31202053297"
    after_create do |u|
      u.meta = Factory :meta, :ownable_id => u.id
      u.save
    end
  end

  factory :employee do
    username 'employee'
    email "salor@salorpos.com"
    password "31202023287"
    after_create do |u|
      u.meta = Factory :meta, :ownable_id => u.id
      u.save
    end
  end
  factory :cashier, :class => Employee do
    username 'cashier'
    email "cashier@salorpos.com"
    password "31202003285"
    association :vendor
    association :user
    after_create do |u|
      u.meta = Factory :meta, :ownable_id => u.id
      u.save
      r = Role.find_or_create_by_name :cashier
      u.roles << r
      u.save
      u.drawer = Drawer.new(:amount => 0)
    end
  end
  factory :manager, :class => Employee do
    username 'manager'
    email "manager@salorpos.com"
    password "31202053295"
    association :vendor
    association :user
    after_create do |u|
      u.meta = Factory :meta, :ownable_id => u.id
      u.save
      r = Role.find_or_create_by_name :manager
      u.roles << r
      u.save
      u.drawer = Drawer.new(:amount => 0)
    end
  end



  factory :discount do
    name "test discount"
    start_date Time.now - 1.day
    end_date Time.now + 1.day
    amount 50
    amount_type 'percent'
    association :vendor
    association :category
  end
  factory :configuration do
    association :vendor
    address "None"
  end
  factory :order do
    association :vendor
    association :user
    association :cash_register
  end
  factory :meta do
    vendor_id 0
    ownable_id 0
    ownable_type 'User'
    order_id 0
    cash_register_id 0
    last_order_id 0
    color "#ffffff"
  end
  factory :category do
    name "Test Category"
    association :vendor
  end
  factory :vendor do
    name "TestVendor"
    association :user, :factory => :user
    calculate_tax false
    multi_currency false
    after_create do |v|
      v.configuration = Factory(:configuration, :vendor => v)
      v.save
    end
  end
  factory :cash_register do
    name "Cash Register"
    association :vendor
  end
  factory :tax_profile do
    name "Test Tax Profile"
    value 7
    sku "TP1234"
    association :user
  end
  factory :item_type do
    name "Normal Item"
    behavior "normal"
  end
  factory :item do
    name "Test Item"
    sku "TEST"
    base_price 5.95
    quantity 100
    quantity_sold 0
    association :vendor
    association :tax_profile
    association :item_type, :factory => :item_type
    association :category
    coupon_type 0
    coupon_applies ""
  end
  factory :shipper do
    name "The Shipper"
    association :user
  end
  factory :stock_location do
    name "StockLocation"
    association :vendor
  end
  factory :shipment do
    name "Shipment"
    association :user
    association :vendor
  end
  factory :shipment_item do
    association :shipment
    name "ShipmentItem"
    sku "STEST"
    quantity 1
  end
end
