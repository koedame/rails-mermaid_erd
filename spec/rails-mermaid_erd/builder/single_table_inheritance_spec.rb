require "spec_helper"

# `Complaint < Comment` shares the `comments` table. The diagram is drawn per
# table, so a subclass must not become an entity of its own: its columns are
# already the base class's columns, and its associations describe that table.
describe RailsMermaidErd::Builder do
  describe ".model_data with single table inheritance" do
    let(:result) { described_class.model_data }
    let(:model_names) { result[:Models].map { |m| m[:ModelName] } }
    let(:endpoints) { result[:Relations].flat_map { |r| [r[:LeftModelName], r[:RightModelName]] } }

    it "emits the shared table once, as the base class" do
      expect(result[:Models].count { |m| m[:TableName] == "comments" }).to eq(1)
      expect(model_names).to include("Comment")
      expect(model_names).not_to include("Complaint")
    end

    it "does not repeat the associations a subclass inherits from its base class" do
      labels = result[:Relations]
        .select { |r| ([r[:LeftModelName], r[:RightModelName]] & ["Comment", "Complaint"]).any? }
        .flat_map { |r| r[:Comment].split(", ") }
      expect(labels.count("BT:post")).to eq(1)
      expect(labels.count("BT:author")).to eq(1)
    end

    it "draws an association declared only on the subclass from the base class" do
      expect(result[:Relations]).to include(
        hash_including(LeftModelName: "Comment", RightModelName: "Comment", Comment: "BT:flagged_comment")
      )
    end

    it "points an association that targets the subclass at the base class" do
      expect(result[:Relations]).to include(
        hash_including(LeftModelName: "Post", RightModelName: "Comment", Comment: "BT:post, HM:comments, HM:complaints")
      )
    end

    it "never names the subclass as a relation endpoint" do
      expect(endpoints).not_to include("Complaint")
    end
  end
end
