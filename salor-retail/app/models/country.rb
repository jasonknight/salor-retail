class Country < ActiveRecord::Base
  include SalorScope
  include SalorBase
  include SalorModel
end
