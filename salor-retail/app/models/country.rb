class Country < ActiveRecord::Base
  include SalorScope
  include SalorBase
  include SalorModel
  
  has_many :invoice_notes
end
