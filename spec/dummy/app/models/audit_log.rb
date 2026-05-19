class AuditLog < ApplicationRecord
  belongs_to :user, class_name: "Author", foreign_key: "user_id"
end
