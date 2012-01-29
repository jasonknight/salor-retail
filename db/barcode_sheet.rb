v = Vendor.all
@vendor = v.first
puts "VID is #{@vendor.id}"
GlobalData.session = {:vendor_id => @vendor.id}
puts "Session: #{GlobalData.salor_user.meta.vendor_id}"
@tp = TaxProfile.first
@cashier = Employee.find_by_username('cashier')
GlobalData.user_id = @cashier.user.id
@register = CashRegister.where("vendor_id = ?",@vendor.id).first
GlobalData.crd = CashRegisterDaily.new(:start_amount => 150, :cash_register_id => @register.id)
GlobalData.crd.set_model_owner(@cashier)

items = Item.scopied.where("sku LIKE 'I%'").limit(12)
puts Item.scopied.where("sku LIKE 'I%'").limit(12).to_sql

b = Barcode.new

b.page do |p|
  p.barcodes = []
  items.each do |item|
    p.barcodes << item.sku
  end
  p.table = {:cols => 2, :rows => 6,:top => 0.5,:left => 0.5, :right => 0.5, :bottom => 0.5}
  p.page_width = 210
  p.page_height = 297
  p.filename = "#{RAILS_ROOT}/barcode_sheet.ps"
  p.encoding = "39"
  p.create
end
