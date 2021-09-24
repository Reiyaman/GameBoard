class CreateReviews < ActiveRecord::Migration[6.1]
  def change
    create_table :reviews do |t|
      t.text :evaluation
      t.integer :star
      t.integer :review_id
      t.integer :reviewed_id
      
      t.timestamps null: false
    end
  end
end
