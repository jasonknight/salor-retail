class AddReportRoles < ActiveRecord::Migration
  def up
    Role.create(:name => "any_reports")
    [:index,:edit,:show,:destroy,:create,:update].each do |t|
      Role.create(:name => "#{t}_reports")
    end
  end

  def down
  end
end
