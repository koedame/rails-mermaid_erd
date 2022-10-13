require "spec_helper"

describe RailsMermaidErd::Builder.model_data do
  let(:result) { RailsMermaidErd::Builder.model_data }

  it "Model includes" do
    expect(result[:Models]).to match_array([{
      TableName: "user_images",
      ModelName: "UserImage",
      IsModelExist: true,
      Columns: [
        {name: "id", type: :integer, key: "PK", comment: nil},
        {name: "image", type: :string, key: "", comment: "Avatar image"},
        {name: "user_id", type: :integer, key: "FK", comment: nil},
        {name: "created_at", type: :datetime, key: "", comment: nil},
        {name: "updated_at", type: :datetime, key: "", comment: nil}
      ]
    }, {
      TableName: "tags",
      ModelName: "Tag",
      IsModelExist: true,
      Columns: [
        {name: "id", type: :integer, key: "PK", comment: nil},
        {name: "name", type: :string, key: "", comment: "always lowercase"},
        {name: "created_at", type: :datetime, key: "", comment: nil},
        {name: "updated_at", type: :datetime, key: "", comment: nil}
      ]
    }, {
      TableName: "posts_tags",
      ModelName: "PostsTag",
      IsModelExist: true,
      Columns: [
        {name: "id", type: :integer, key: "PK", comment: nil},
        {name: "post_id", type: :integer, key: "FK", comment: nil},
        {name: "tag_id", type: :integer, key: "FK", comment: nil},
        {name: "created_at", type: :datetime, key: "", comment: nil},
        {name: "updated_at", type: :datetime, key: "", comment: nil}
      ]
    }, {
      TableName: "posts",
      ModelName: "Post",
      IsModelExist: true,
      Columns: [
        {name: "id", type: :integer, key: "PK", comment: nil},
        {name: "title", type: :string, key: "", comment: "post title"},
        {name: "user_id", type: :integer, key: "FK", comment: nil},
        {name: "created_at", type: :datetime, key: "", comment: nil},
        {name: "updated_at", type: :datetime, key: "", comment: nil}
      ]
    }, {
      TableName: "comments",
      ModelName: "Comment",
      IsModelExist: true,
      Columns: [
        {name: "id", type: :integer, key: "PK", comment: nil},
        {name: "body", type: :string, key: "", comment: nil},
        {name: "post_id", type: :integer, key: "FK", comment: nil},
        {name: "user_id", type: :integer, key: "FK", comment: nil},
        {name: "created_at", type: :datetime, key: "", comment: nil},
        {name: "updated_at", type: :datetime, key: "", comment: nil}
      ]
    }, {
      TableName: "user_profiles",
      ModelName: "AuthorProfile",
      IsModelExist: true,
      Columns: [
        {name: "id", type: :integer, key: "PK", comment: nil},
        {name: "birthday", type: :date, key: "", comment: "Birthday"},
        {name: "user_id", type: :integer, key: "FK", comment: nil},
        {name: "created_at", type: :datetime, key: "", comment: nil},
        {name: "updated_at", type: :datetime, key: "", comment: nil}
      ]
    }, {
      TableName: "users",
      ModelName: "Author",
      IsModelExist: true,
      Columns: [
        {name: "id", type: :integer, key: "PK", comment: nil},
        {name: "name", type: :string, key: "", comment: "nickname"},
        {name: "email", type: :string, key: "", comment: "login email"},
        {name: "created_at", type: :datetime, key: "", comment: nil},
        {name: "updated_at", type: :datetime, key: "", comment: nil}
      ]
    }])
  end

  it "Relation includes" do
    expect(result[:Relations]).to match_array([{
      LeftModelName: "UserImage",
      LeftValue: "}o",
      RightModelName: "Author",
      RightValue: "o|",
      Comment: include("belongs_to user", "has_many images")
    }, {
      LeftModelName: "PostsTag",
      LeftValue: "}o",
      RightModelName: "Post",
      RightValue: "||",
      Comment: ""
    }, {
      LeftModelName: "Tag",
      LeftValue: "}o",
      RightModelName: "Post",
      RightValue: "o{",
      Comment: "HABTM"
    }, {
      LeftModelName: "PostsTag",
      LeftValue: "}o",
      RightModelName: "Tag",
      RightValue: "||",
      Comment: ""
    }, {
      LeftModelName: "Post",
      LeftValue: "||",
      RightModelName: "Comment",
      RightValue: "o{",
      Comment: ""
    }, {
      LeftModelName: "Post",
      LeftValue: "}o",
      RightModelName: "Author",
      RightValue: "||",
      Comment: ""
    }, {
      LeftModelName: "Comment",
      LeftValue: "}o",
      RightModelName: "Author",
      RightValue: "||",
      Comment: ""
    }, {
      LeftModelName: "AuthorProfile",
      LeftValue: "|o",
      RightModelName: "Author",
      RightValue: "||",
      Comment: "has_one profile"
    }])
  end
end
