class UserImage < ApplicationRecord
  belongs_to :user, class_name: "Author", foreign_key: "user_id", optional: true
end
