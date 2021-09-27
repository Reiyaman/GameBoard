class CreateReviews < ActiveRecord::Migration[6.1]
  def change
    create_table :reviews do |t|
      t.text :evaluation
      t.float :star
      t.integer :reviewer_id
      t.integer :reviewed_id
      
      t.timestamps null: false
    end
  end
end
