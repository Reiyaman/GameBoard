class CreateChats < ActiveRecord::Migration[6.1]
  def change
    create_table :chats do |t|
      t.text :comment
      t.integer :talkroom_id
      t.integer :user_id
      
      t.timestamps null: false
    end
  end
end
