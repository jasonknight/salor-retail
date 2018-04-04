class AddVendorFieldsToAllModels < ActiveRecord::Migration
  def up
    ActiveRecord::Base.connection.tables.each do |t|      
      begin
        model = t.classify.constantize
        model.reset_column_information
      rescue
        next
      end

      if not model.column_names.include? 'vendor_id' then
        puts "Adding :vendor_id column :integer to #{model}"
        add_column model.table_name.to_sym, :vendor_id, :integer
      end
      
      if not model.column_names.include? 'company_id' then
        puts "Adding :company_id column :integer to #{model}"
        add_column model.table_name.to_sym, :company_id, :integer
      end
    end
  end
  
  def down
  end
end
