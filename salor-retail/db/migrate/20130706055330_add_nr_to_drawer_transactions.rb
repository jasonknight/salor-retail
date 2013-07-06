class AddNrToDrawerTransactions < ActiveRecord::Migration
  def change
    add_column :drawer_transactions, :nr, :integer
    add_column :vendors, :largest_drawer_transaction_number, :integer
    Vendor.all.each do |v|
      i = 0
      puts "numbering all drawer transactions for vendor #{v.id}"
      v.drawer_transactions.order("created_at asc").each do |dt|
        i += 1
        dt.update_attribute(:nr,i)
      end
      v.update_attribute :largest_drawer_transaction_number, i
    end
  end
end
