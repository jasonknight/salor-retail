# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class Shipper < ActiveRecord::Base
  include SalorScope
  include SalorBase

  has_many :shipments, :as => :shipper
  has_many :returns, :as => :receiver
  has_many :items
  has_many :broken_items
  belongs_to :user
  belongs_to :vendor
  belongs_to :company
  
  validates_presence_of :name
  validates_presence_of :vendor_id, :company_id
  
  def fetch_csv
    log_action "fetch_csv for #{ self.name }: called"
    file = SalorBase.get_url(self.csv_url)
    data = file.body
    log_action "fetch_csv for #{ self.name }: body size is #{ data.size }"
    return data
  end
  
  def import_csv(data)
    log_action "import_csv for #{ self.name }: creating FileUpload objcet"
    uploader = FileUpload.new(self, data)
    log_action "import_csv for #{ self.name }: Letting FileUpload crunch"
    uploader.crunch
    return uploader
  end
  
  def fetch_and_import_csv
    log_action "fetch_and_import_csv for #{ self.name }: Fetching CSV"
    data = self.fetch_csv
    log_action "fetch_and_import_csv for #{ self.name }: Importing CSV"
    uploader = self.import_csv(data)
    return uploader
  end
  
  # Reorder recommendation csvs
  # TODO: The following 3 methods should go into Shipper
#   def self.recommend_reorder(type)
#     shippers = Shipper.where(:vendor_id => @current_user.vendor_id).visible.find_all_by_reorder_type(type)
#     shippers << nil if type == 'default_export'
#     items = Item.scopied.visible.where("quantity < min_quantity AND (ignore_qty IS FALSE OR ignore_qty IS NULL)").where(:shipper_id => shippers)
#     if not items.any? then
#       return nil 
#     end
#     unless type == 'default_export'
#       # Now we need to create a shipment
#       shipment = Shipment.new({
#           :name => I18n.t("activerecord.models.shipment.default_name") + " - " + Time.now,
#           :price => items.sum(:purchase_price),
#           :receiver_id => $Vendor.id,
#           :receiver_type => 'Vendor',
#           :shipper_id => shippers.first.id,
#           :shipment_type => ShipmentType.scopied.first,
#           :shipper_type => 'Shipper'
#       })
#       shipment.save
#       items.each do |item|
#         si = ShipmentItem.new({
#             :name => item.name,
#             :base_price => item.base_price,
#             :category_id => item.category_id,
#             :location_id => item.location_id,
#             :item_type_id => item.item_type_id,
#             :shipment_id => shipment.id,
#             :sku => item.sku,
#             :quantity => item.min_quantity - item.quantity,
#             :vendor_id => $Vendor.id
#         })
#         si.save
#       end
#     end
#     return Item.send(type.to_sym,items)
#   end
#   
#   def self.tobacco_land(items)
#     lines = []
#     items.each do |item|
#       sku = item.shipper_sku.blank? ? item.sku[0..3] : item.shipper_sku[0..3]
#       lines << "%s %04d" % [sku,(item.min_quantity - item.quantity).to_i] 
#     end
#     return lines.join("\x0D\x0A")
#   end
#   
#   def self.default_export(items)
#     lines = []
#     items.each do |item|
#       shippername = item.shipper ? item.shipper.name : ''
#       lines << "%s\t%s\t%s\t%d\t%f" % [shippername,item.name,item.sku,(item.min_quantity - item.quantity).to_i,item.purchase_price.to_f]
#     end
#     return lines.join("\n")
#   end
end


