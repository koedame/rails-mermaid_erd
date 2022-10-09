class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :name, null: false, comment: "nickname"
      t.string :email, null: false, comment: "login email"

      t.timestamps
    end
  end
end
