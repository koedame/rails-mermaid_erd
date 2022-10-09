class AuthorProfile < ApplicationRecord
  self.table_name = "user_profiles"
  belongs_to :author, foreign_key: "user_id"
end
