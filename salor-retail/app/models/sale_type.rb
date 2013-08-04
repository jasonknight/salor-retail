class SaleType < ActiveRecord::Base
  include SalorScope
  include SalorBase
  
  belongs_to :vendor
  belongs_to :company
  
  validates_presence_of :vendor_id, :company_id, :name

  def as_json(x)
    return {:id=> self.id, :name=> self.name,:vendor_id=>self.vendor_id}
  end
end
