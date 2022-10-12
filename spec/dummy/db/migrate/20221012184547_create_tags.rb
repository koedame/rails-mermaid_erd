class CreateTags < ActiveRecord::Migration[7.0]
  def change
    create_table :tags do |t|
      t.string :name, null: false, comment: "always lowercase"

      t.timestamps
    end
  end
end
