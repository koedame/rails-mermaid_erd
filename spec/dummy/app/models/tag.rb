class Tag < ApplicationRecord
  has_and_belongs_to_many :posts
  # Names an inverse that doesn't exist. Rails only complains once the
  # association is used, so the diagram must still be drawn.
  has_many :posts_tags, inverse_of: :label
end
