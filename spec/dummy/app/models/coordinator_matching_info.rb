class CoordinatorMatchingInfo < ApplicationRecord
  has_many :matching_info_care_types, as: :matching_info
  has_many :care_types, through: :matching_info_care_types
end
