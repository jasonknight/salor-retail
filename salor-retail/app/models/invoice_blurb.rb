class InvoiceBlurb < ActiveRecord::Base
  include SalorScope
  include SalorBase
  
  belongs_to :vendor
  belongs_to :company
  
  validates_uniqueness_of :is_header, :scope => [:vendor_id, :lang]
  validates_presence_of :vendor_id, :company_id
end
