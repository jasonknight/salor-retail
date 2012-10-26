# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :manager_role, :class => Role do
    name "manager"
  end
  factory :cashier_role, :class => Role do
    name "cashier"
  end
end
