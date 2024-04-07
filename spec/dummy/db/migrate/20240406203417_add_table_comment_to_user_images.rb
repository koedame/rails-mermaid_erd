class AddTableCommentToUserImages < ActiveRecord::Migration[7.0]
def change
    change_table_comment(:user_images, from: nil, to: 'uploaded image by user')
  end
end
