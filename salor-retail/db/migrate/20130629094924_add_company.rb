class AddCompany < ActiveRecord::Migration
  def up
    c = Company.new
    c.name = "default"
    c.identifier = "default"
    c.save
    cid = c.id
    
    
    ActiveRecord::Base.connection.tables.each do |t|      
      begin
        model = t.classify.constantize
        model.reset_column_information
      rescue
        next
      end
      
      if model.column_names.include? 'company_id' then
        puts "Setting #{ t } to company_id #{ cid }"
        model.connection.execute("UPDATE #{ t } SET company_id=#{ cid };")
      end
    end
  end

  def down
  end
end
