require "spec_helper"

# Associations that describe the same link between two tables are drawn as one
# line, and associations that describe different links are drawn as separate
# lines. Which models happen to sort first must not change either outcome.
describe RailsMermaidErd::Builder do
  describe ".model_data merging associations into relation lines" do
    let(:result) { described_class.model_data }
    let(:author_post_lines) do
      result[:Relations].select { |r| [r[:LeftModelName], r[:RightModelName]].sort == ["Author", "Post"] && r[:Line] == "--" }
    end
    let(:author_comment_lines) do
      result[:Relations].select { |r| [r[:LeftModelName], r[:RightModelName]].sort == ["Author", "Comment"] && r[:Line] == "--" }
    end

    context "when a model belongs to the same model twice and only one link is optional" do
      it "keeps the required link drawn as required" do
        expect(author_post_lines).to include(
          hash_including(LeftModelName: "Author", LeftValue: "||", RightModelName: "Post", RightValue: "o{", Comment: "HM:posts, BT:author")
        )
      end

      it "draws the optional link as its own optional line" do
        expect(author_post_lines).to include(
          hash_including(LeftModelName: "Author", LeftValue: "|o", RightModelName: "Post", RightValue: "o{", Comment: "BT:editor")
        )
      end
    end

    context "when a model that sorts before its target has many of it twice through the same foreign key" do
      it "draws a single line naming both associations" do
        expect(author_comment_lines).to contain_exactly(
          hash_including(LeftModelName: "Author", RightModelName: "Comment", Comment: "HM:comments, HM:recent_comments, BT:author")
        )
      end
    end

    context "when a model that sorts after its target has many of it twice through the same foreign key" do
      it "draws a single line naming both associations" do
        lines = result[:Relations].select { |r| [r[:LeftModelName], r[:RightModelName]].sort == ["Comment", "Post"] }
        expect(lines).to contain_exactly(
          hash_including(LeftModelName: "Post", RightModelName: "Comment", Comment: "BT:post, HM:comments, HM:complaints")
        )
      end
    end

    context "when a model has one of another model through a third" do
      it "draws the end it reaches as at most one" do
        expect(result[:Relations]).to include(
          {LeftModelName: "AuthorProfile", LeftValue: "|o", Line: "..", RightModelName: "UserImage", RightValue: "o{", Comment: "HOT:profile"}
        )
      end
    end
  end
end
