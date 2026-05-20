require "spec_helper"

describe RailsMermaidErd::Builder.model_data do
  let(:result) { RailsMermaidErd::Builder.model_data }

  it "Model includes" do
    expect(result[:Models]).to match_array([{
      TableName: "audit_logs",
      TableComment: "",
      ModelName: "AuditLog",
      IsModelExist: true,
      Columns: [
        {name: "id", type: :integer, key: "PK", comment: nil},
        {name: "action", type: :string, key: "", comment: nil},
        {name: "created_at", type: :datetime, key: "", comment: nil},
        {name: "updated_at", type: :datetime, key: "", comment: nil},
        {name: "user_id", type: :integer, key: "FK", comment: nil}
      ]
    }, {
      TableName: "user_images",
      TableComment: "uploaded image by user",
      ModelName: "UserImage",
      IsModelExist: true,
      Columns: [
        {name: "id", type: :integer, key: "PK", comment: nil},
        {name: "created_at", type: :datetime, key: "", comment: nil},
        {name: "image", type: :string, key: "", comment: "Avatar image"},
        {name: "updated_at", type: :datetime, key: "", comment: nil},
        {name: "user_id", type: :integer, key: "FK", comment: nil}
      ]
    }, {
      TableName: "tags",
      TableComment: "",
      ModelName: "Tag",
      IsModelExist: true,
      Columns: [
        {name: "id", type: :integer, key: "PK", comment: nil},
        {name: "created_at", type: :datetime, key: "", comment: nil},
        {name: "name", type: :string, key: "", comment: "always lowercase"},
        {name: "updated_at", type: :datetime, key: "", comment: nil}
      ]
    }, {
      TableName: "posts_tags",
      TableComment: "",
      ModelName: "PostsTag",
      IsModelExist: true,
      Columns: [
        {name: "id", type: :integer, key: "PK", comment: nil},
        {name: "created_at", type: :datetime, key: "", comment: nil},
        {name: "post_id", type: :integer, key: "FK", comment: nil},
        {name: "tag_id", type: :integer, key: "FK", comment: nil},
        {name: "updated_at", type: :datetime, key: "", comment: nil}
      ]
    }, {
      TableName: "posts",
      TableComment: "",
      ModelName: "Post",
      IsModelExist: true,
      Columns: [
        {name: "id", type: :integer, key: "PK", comment: nil},
        {name: "created_at", type: :datetime, key: "", comment: nil},
        {name: "title", type: :string, key: "", comment: "post title"},
        {name: "updated_at", type: :datetime, key: "", comment: nil},
        {name: "user_id", type: :integer, key: "FK", comment: nil}
      ]
    }, {
      TableName: "comments",
      TableComment: "",
      ModelName: "Comment",
      IsModelExist: true,
      Columns: [
        {name: "id", type: :integer, key: "PK", comment: nil},
        {name: "body", type: :string, key: "", comment: nil},
        {name: "created_at", type: :datetime, key: "", comment: nil},
        {name: "post_id", type: :integer, key: "FK", comment: nil},
        {name: "updated_at", type: :datetime, key: "", comment: nil},
        {name: "user_id", type: :integer, key: "FK", comment: nil}
      ]
    }, {
      TableName: "user_profiles",
      TableComment: "",
      ModelName: "AuthorProfile",
      IsModelExist: true,
      Columns: [
        {name: "id", type: :integer, key: "PK", comment: nil},
        {name: "birthday", type: :date, key: "", comment: "Birthday"},
        {name: "created_at", type: :datetime, key: "", comment: nil},
        {name: "updated_at", type: :datetime, key: "", comment: nil},
        {name: "user_id", type: :integer, key: "FK", comment: nil}
      ]
    }, {
      TableName: "users",
      TableComment: "",
      ModelName: "Author",
      IsModelExist: true,
      Columns: [
        {name: "id", type: :integer, key: "PK", comment: nil},
        {name: "created_at", type: :datetime, key: "", comment: nil},
        {name: "email", type: :string, key: "", comment: "login email"},
        {name: "name", type: :string, key: "", comment: "nickname"},
        {name: "updated_at", type: :datetime, key: "", comment: nil}
      ]
    }, {
      TableName: "care_types",
      TableComment: "",
      ModelName: "CareType",
      IsModelExist: true,
      Columns: [
        {name: "id", type: :integer, key: "PK", comment: nil},
        {name: "created_at", type: :datetime, key: "", comment: nil},
        {name: "name", type: :string, key: "", comment: nil},
        {name: "updated_at", type: :datetime, key: "", comment: nil}
      ]
    }, {
      TableName: "caregiver_matching_infos",
      TableComment: "",
      ModelName: "CaregiverMatchingInfo",
      IsModelExist: true,
      Columns: [
        {name: "id", type: :integer, key: "PK", comment: nil},
        {name: "created_at", type: :datetime, key: "", comment: nil},
        {name: "first_name", type: :string, key: "", comment: nil},
        {name: "updated_at", type: :datetime, key: "", comment: nil}
      ]
    }, {
      TableName: "coordinator_matching_infos",
      TableComment: "",
      ModelName: "CoordinatorMatchingInfo",
      IsModelExist: true,
      Columns: [
        {name: "id", type: :integer, key: "PK", comment: nil},
        {name: "created_at", type: :datetime, key: "", comment: nil},
        {name: "first_name", type: :string, key: "", comment: nil},
        {name: "updated_at", type: :datetime, key: "", comment: nil}
      ]
    }, {
      TableName: "matching_info_care_types",
      TableComment: "",
      ModelName: "MatchingInfoCareType",
      IsModelExist: true,
      Columns: [
        {name: "id", type: :integer, key: "PK", comment: nil},
        {name: "care_type_id", type: :integer, key: "FK", comment: nil},
        {name: "created_at", type: :datetime, key: "", comment: nil},
        {name: "matching_info_id", type: :integer, key: "", comment: nil},
        {name: "matching_info_type", type: :string, key: "", comment: nil},
        {name: "updated_at", type: :datetime, key: "", comment: nil}
      ]
    }])
  end

  it "Relation includes" do
    expect(result[:Relations]).to match_array([{
      LeftModelName: "AuditLog",
      LeftValue: "}o",
      Line: "--",
      RightModelName: "Author",
      RightValue: "||",
      Comment: "BT:user, HM:audit_logs"
    }, {
      LeftModelName: "Author",
      LeftValue: "||",
      Line: "--",
      RightModelName: "Post",
      RightValue: "o{",
      Comment: "HM:posts, BT:author"
    }, {
      LeftModelName: "Author",
      LeftValue: "||",
      Line: "--",
      RightModelName: "Comment",
      RightValue: "o{",
      Comment: "HM:comments, BT:author"
    }, {
      LeftModelName: "Author",
      LeftValue: "}o",
      Line: "..",
      RightModelName: "Post",
      RightValue: "o{",
      Comment: "HMT:comment_posts, HMT:comment_authors"
    }, {
      LeftModelName: "Author",
      LeftValue: "|o",
      Line: "--",
      RightModelName: "UserImage",
      RightValue: "o{",
      Comment: "HM:images, BT:user"
    }, {
      LeftModelName: "Author",
      LeftValue: "||",
      Line: "--",
      RightModelName: "AuthorProfile",
      RightValue: "o|",
      Comment: "HO:profile, BT:author"
    }, {
      LeftModelName: "Comment",
      LeftValue: "}o",
      Line: "--",
      RightModelName: "Post",
      RightValue: "||",
      Comment: "BT:post, HM:comments"
    }, {
      LeftModelName: "Post",
      LeftValue: "}o",
      Line: "..",
      RightModelName: "Tag",
      RightValue: "o{",
      Comment: "HABTM"
    }, {
      LeftModelName: "PostsTag",
      LeftValue: "}o",
      Line: "--",
      RightModelName: "Post",
      RightValue: "||",
      Comment: "BT:post"
    }, {
      LeftModelName: "PostsTag",
      LeftValue: "}o",
      Line: "--",
      RightModelName: "Tag",
      RightValue: "||",
      Comment: "BT:tag"
    }, {
      LeftModelName: "CareType",
      LeftValue: "||",
      Line: "--",
      RightModelName: "MatchingInfoCareType",
      RightValue: "o{",
      Comment: "HM:matching_info_care_types, BT:care_type"
    }, {
      LeftModelName: "CareType",
      LeftValue: "}o",
      Line: "..",
      RightModelName: "CoordinatorMatchingInfo",
      RightValue: "o{",
      Comment: "HMT:coordinator_matching_infos, HMT:care_types"
    }, {
      LeftModelName: "CareType",
      LeftValue: "}o",
      Line: "..",
      RightModelName: "CaregiverMatchingInfo",
      RightValue: "o{",
      Comment: "HMT:caregiver_matchings, HMT:care_types"
    }, {
      LeftModelName: "CaregiverMatchingInfo",
      LeftValue: "||",
      Line: "--",
      RightModelName: "MatchingInfoCareType",
      RightValue: "o{",
      Comment: "HM:matching_info_care_types"
    }, {
      LeftModelName: "CoordinatorMatchingInfo",
      LeftValue: "||",
      Line: "--",
      RightModelName: "MatchingInfoCareType",
      RightValue: "o{",
      Comment: "HM:matching_info_care_types"
    }])
  end
end
