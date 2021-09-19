class CreateJoins < ActiveRecord::Migration[6.1]
  def change
    create_table :joins do |t|
      t.integer :user_id
      t.integer :talkroom_id
      
      t.timestamps null: false
    end
  end
end
