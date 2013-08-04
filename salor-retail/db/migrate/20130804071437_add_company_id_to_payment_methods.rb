class AddCompanyIdToPaymentMethods < ActiveRecord::Migration
  def change
    add_column :payment_methods, :company_id, :integer
    Vendor.all.each do |v|
      puts "Updating company_id for all paymentMethods of Vendor #{ v.id }"
      v.payment_methods.update_all :company_id => v.company_id
    end
  end
end
