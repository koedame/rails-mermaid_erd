class AddSingleTableInheritanceToComments < ActiveRecord::Migration[5.2]
  def change
    add_column :comments, :type, :string
    add_reference :comments, :flagged_comment, foreign_key: {to_table: :comments}
  end
end
