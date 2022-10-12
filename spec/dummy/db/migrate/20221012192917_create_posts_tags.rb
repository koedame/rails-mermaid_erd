class CreatePostsTags < ActiveRecord::Migration[7.0]
  def change
    create_table :posts_tags do |t|
      t.references :post, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end
  end
end
