class CreateRecruits < ActiveRecord::Migration[6.1]
  def change
    create_table :recruits do |t|
      t.integer :model_id
      t.integer :game_id
      t.integer :category_id
      t.text :article
      t.integer :user_id
      t.datetime :articletime
      t.boolean :status
    end
  end
end
