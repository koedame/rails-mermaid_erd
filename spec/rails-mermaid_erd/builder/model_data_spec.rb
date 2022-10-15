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
      Line: "--",
      RightModelName: "Author",
      RightValue: "o|",
      Comment: "BT:user, HM:images"
    }, {
      LeftModelName: "Tag",
      LeftValue: "}o",
      Line: "..",
      RightModelName: "Post",
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
      LeftModelName: "Post",
      LeftValue: "||",
      Line: "--",
      RightModelName: "Comment",
      RightValue: "o{",
      Comment: "HM:comments, BT:post"
    }, {
      LeftModelName: "Post",
      LeftValue: "}o",
      Line: "..",
      RightModelName: "Author",
      RightValue: "o{",
      Comment: "HMT:comment_authors, HMT:comment_posts"
    }, {
      LeftModelName: "Post",
      LeftValue: "}o",
      Line: "--",
      RightModelName: "Author",
      RightValue: "||",
      Comment: "BT:author, HM:posts"
    }, {
      LeftModelName: "Comment",
      LeftValue: "}o",
      Line: "--",
      RightModelName: "Author",
      RightValue: "||",
      Comment: "BT:author, HM:comments"
    }, {
      LeftModelName: "AuthorProfile",
      LeftValue: "|o",
      Line: "--",
      RightModelName: "Author",
      RightValue: "||",
      Comment: "BT:author, HO:profile"
    }])
  end
end
