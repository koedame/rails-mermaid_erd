class MatchingInfoCareType < ApplicationRecord
  belongs_to :care_type
  belongs_to :matching_info, polymorphic: true
end
