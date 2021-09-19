class CreateTalkrooms < ActiveRecord::Migration[6.1]
  def change
    create_table :talkrooms do |t|
      t.integer :recruit_id
      
      t.timestamps null: false
    end
  end
end
