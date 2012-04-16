# do something like: rails g migration update_from_old_version_to_version
class UpdateFromStargazerToBabylonFive < ActiveRecord::Migration
# COPY CODE BETWEEN HERE AND END COMMENT INTO BODY OF MIGRATION
  def up
    msg = %Q[
      Ugrade from old_version to new_version
      Noteworthy Changes:
        Change 1
        Change 2
    ]
    h = History.new(:owner_type => "System",:owner_id => '1', :sensitivity => 1,:changes_made => {:version => ["old_version","new_version"], :msg => ['',msg]}.to_json)
    h.save
    end
  end

  def down
  end
# END OF CODE THAT SHOULD BE COPIED
end
