# Both associations rest on columns that have no foreign key constraint.
class Bookmark < ApplicationRecord
  belongs_to :post
  belongs_to :reader, class_name: "Author"
end
