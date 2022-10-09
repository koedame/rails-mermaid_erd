class Author < ApplicationRecord
  self.table_name = "users"

  has_many :posts, dependent: :destroy
  has_many :comments
  has_many :comment_posts, through: :comments, source: :post
  has_one :profile, class_name: "AuthorProfile", foreign_key: "user_id", dependent: :destroy
  has_many :images, class_name: "UserImage", foreign_key: "user_id", dependent: :destroy
end
