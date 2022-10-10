class CreateUserProfiles < ActiveRecord::Migration[7.0]
  def change
    create_table :user_profiles do |t|
      t.date :birthday, null: false, comment: "Birthday"
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
