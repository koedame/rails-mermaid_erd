class Post < ApplicationRecord
  belongs_to :author
  has_many :comments
  has_many :comment_authors, through: :comments, source: :author
end
