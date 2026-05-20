require "spec_helper"

describe RailsMermaidErd::Builder do
  describe ".model_data with ignore_tables" do
    let(:result) { described_class.model_data }

    # `RailsMermaidErd.configuration` is memoized at module level
    # (`lib/rails-mermaid_erd.rb`), so we mutate the existing singleton and
    # restore it after each example rather than swapping the whole object —
    # otherwise every other spec in this process would have to know about us.
    around do |example|
      original = RailsMermaidErd.configuration.ignore_tables
      RailsMermaidErd.configuration.ignore_tables = ignore_tables
      example.run
    ensure
      RailsMermaidErd.configuration.ignore_tables = original
    end

    context "when a pattern matches a `belongs_to` target" do
      let(:ignore_tables) { ["\\Aaudit_"] }

      it "drops the matching model from Models" do
        expect(result[:Models].map { |m| m[:ModelName] }).not_to include("AuditLog")
      end

      it "keeps the unmatched models" do
        expect(result[:Models].map { |m| m[:ModelName] }).to include("Author", "Post", "Comment")
      end

      # `model_data_spec.rb` documents that without ignore_tables there's a
      # single merged `AuditLog ↔ Author` relation (HM + BT combined). Verify
      # both halves of that merge are gone — checking endpoint membership
      # alone would pass even if e.g. the `belongs_to` filter regressed and
      # left a `Author → AuditLog` edge dangling.
      it "drops both halves of the merged AuditLog/Author relation" do
        author_audit = result[:Relations].find do |r|
          [r[:LeftModelName], r[:RightModelName]].sort == ["AuditLog", "Author"]
        end
        expect(author_audit).to be_nil
      end

      it "leaves untouched relations intact" do
        expect(result[:Relations]).to include(
          hash_including(LeftModelName: "Author", RightModelName: "Post", Comment: "HM:posts, BT:author")
        )
      end
    end

    context "when a pattern matches a `has_one` target" do
      let(:ignore_tables) { ["\\Auser_profiles\\z"] }

      it "drops the AuthorProfile model and its has_one relation with Author" do
        expect(result[:Models].map { |m| m[:ModelName] }).not_to include("AuthorProfile")
        endpoints = result[:Relations].flat_map { |r| [r[:LeftModelName], r[:RightModelName]] }
        expect(endpoints).not_to include("AuthorProfile")
      end
    end

    context "when a pattern matches a HABTM target" do
      let(:ignore_tables) { ["\\Atags\\z"] }

      it "drops Tag and both sides of the Post HABTM Tag relation" do
        expect(result[:Models].map { |m| m[:ModelName] }).not_to include("Tag")
        endpoints = result[:Relations].flat_map { |r| [r[:LeftModelName], r[:RightModelName]] }
        expect(endpoints).not_to include("Tag")
      end
    end

    context "when a pattern matches a `has_many :through` target" do
      let(:ignore_tables) { ["\\Aposts\\z"] }

      it "drops Post and every relation touching it" do
        expect(result[:Models].map { |m| m[:ModelName] }).not_to include("Post")
        endpoints = result[:Relations].flat_map { |r| [r[:LeftModelName], r[:RightModelName]] }
        expect(endpoints).not_to include("Post")
      end
    end

    context "when multiple patterns are configured" do
      let(:ignore_tables) { ["\\Aaudit_", "\\Auser_profiles\\z"] }

      it "drops every model matched by any pattern" do
        names = result[:Models].map { |m| m[:ModelName] }
        expect(names).not_to include("AuditLog", "AuthorProfile")
        expect(names).to include("Author", "Post")
      end
    end

    context "when no pattern matches" do
      let(:ignore_tables) { ["\\Aunused_table_"] }

      it "still emits AuditLog and other defaults" do
        expect(result[:Models].map { |m| m[:ModelName] }).to include("AuditLog", "Author", "Post")
      end
    end

    context "when ignore_tables is empty" do
      let(:ignore_tables) { [] }

      it "emits every model that would be emitted without the option" do
        expect(result[:Models].map { |m| m[:ModelName] }).to include("AuditLog")
      end
    end

    context "when a pattern is an invalid regex" do
      let(:ignore_tables) { ["[unclosed"] }

      it "raises ArgumentError naming the offending pattern" do
        expect { result }.to raise_error(ArgumentError, /\[unclosed/)
      end
    end
  end
end
