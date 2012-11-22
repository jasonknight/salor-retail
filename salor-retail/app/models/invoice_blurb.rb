class InvoiceBlurb < ActiveRecord::Base

  attr_accessible :body, :is_header, :lang
  belongs_to :vendor
  include SalorScope
  validates_uniqueness_of :is_header, :scope => [:vendor_id, :lang]
end
