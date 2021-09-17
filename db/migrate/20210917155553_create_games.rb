class CreateGames < ActiveRecord::Migration[6.1]
  def change
    create_table :games do |t|
      t.string :gamename
      t.integer :model_id
      t.integer :category_id
    end
  end
end
