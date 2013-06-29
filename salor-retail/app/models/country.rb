class Country < ActiveRecord::Base
  include SalorScope
  include SalorBase

  def as_json(x)
    return {:id=> self.id,:name => self.name, :vendor_id => self.vendor_id}
  end
end
