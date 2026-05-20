class AddTableCommentToUserImages < ActiveRecord::Migration[5.2]
  def change
    change_table_comment(:user_images, from: nil, to: "uploaded image by user")
  end
end
