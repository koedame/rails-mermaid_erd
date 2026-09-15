class AddEditorToPosts < ActiveRecord::Migration[5.2]
  def change
    add_reference :posts, :editor, foreign_key: {to_table: :users}
  end
end
