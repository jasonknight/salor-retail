class AddAssistantRoleToRoles < ActiveRecord::Migration
  def change
    role = Role.find_by_name("assistant")
    if not role then
      Role.create(:name => "assistant")
    end
  end
end
