class InvoiceNote < ActiveRecord::Base
  include SalorScope
  include SalorBase
  
  belongs_to :vendor
  belongs_to :company
  
  belongs_to :origin_country, :class_name => 'Country', :foreign_key => 'origin_country_id'
  belongs_to :destination_country, :class_name => 'Country', :foreign_key => 'destination_country_id'
  belongs_to :sale_type
  
  validates_presence_of :origin_country_id
  validates_presence_of :destination_country_id
  validates_presence_of :vendor_id, :company_id
  
  def name
    "#{ self.origin_country.name} -> #{ self.destination_country.name}: #{ self.sale_type.name if self.sale_type }"
  end
end
