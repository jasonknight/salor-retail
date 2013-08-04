class AddCompanyIdToAllModels < ActiveRecord::Migration
  def up
    ActiveRecord::Base.connection.tables.each do |t|      
      begin
        model = t.classify.constantize
        model.reset_column_information
      rescue
        next
      end
      
      if Company.first then
        cid = Company.first.id
      
        if model.column_names.include? 'company_id' then
          puts "Setting #{ t } to company_id #{ cid }"
          model.connection.execute("UPDATE #{ t } SET company_id=#{ cid };")
        end
      end
    end
  end
  
  def down
  end
end
