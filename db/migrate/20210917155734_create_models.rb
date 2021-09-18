class CreateModels < ActiveRecord::Migration[6.1]
  def change
    create_table :models do |t|
      t.string :platform
      
      t.timestamps null: false
    end
  end
end
