class Post < ApplicationRecord
  belongs_to :author
  # A second, optional link to the same model through its own column.
  belongs_to :editor, class_name: "Author", optional: true
  has_many :comments
  has_many :complaints
  has_many :comment_authors, through: :comments, source: :author
  has_and_belongs_to_many :tags
end
