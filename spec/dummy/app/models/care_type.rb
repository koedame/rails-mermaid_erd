class CareType < ApplicationRecord
  has_many :matching_info_care_types
  # Unresolvable polymorphic source — exercises the `source_reflection.nil?` fallback.
  has_many :coordinator_matching_infos, through: :matching_info_care_types
  # Explicit polymorphic disambiguation — exercises the `:source_type` branch.
  has_many :caregiver_matchings,
    through: :matching_info_care_types,
    source: :matching_info,
    source_type: "CaregiverMatchingInfo"
end
