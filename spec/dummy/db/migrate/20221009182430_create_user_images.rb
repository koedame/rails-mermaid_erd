class CreateUserImages < ActiveRecord::Migration[7.0]
  def change
    create_table :user_images do |t|
      t.string :image, null: false, comment: "Avatar image"
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
