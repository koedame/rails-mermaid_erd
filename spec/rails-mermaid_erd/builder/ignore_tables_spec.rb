require "spec_helper"

describe RailsMermaidErd::Builder do
  describe ".model_data with ignore_tables" do
    let(:result) { described_class.model_data }

    around do |example|
      original = RailsMermaidErd.configuration.ignore_tables
      RailsMermaidErd.configuration.ignore_tables = ignore_tables
      example.run
    ensure
      RailsMermaidErd.configuration.ignore_tables = original
    end

    context "when a pattern matches a table name" do
      let(:ignore_tables) { ["\\Aaudit_"] }

      it "drops the matching model from Models" do
        expect(result[:Models].map { |m| m[:ModelName] }).not_to include("AuditLog")
      end

      it "keeps the unmatched models" do
        expect(result[:Models].map { |m| m[:ModelName] }).to include("Author", "Post", "Comment")
      end

      it "drops relations that point at the ignored model from either side" do
        endpoints = result[:Relations].flat_map { |r| [r[:LeftModelName], r[:RightModelName]] }
        expect(endpoints).not_to include("AuditLog")
      end

      it "leaves untouched relations intact" do
        expect(result[:Relations]).to include(
          hash_including(LeftModelName: "Author", RightModelName: "Post", Comment: "HM:posts, BT:author")
        )
      end
    end

    context "when no pattern matches" do
      let(:ignore_tables) { ["\\Aunused_table_"] }

      it "produces the same Models as the default run" do
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

      it "raises RegexpError on the offending pattern" do
        expect { result }.to raise_error(RegexpError)
      end
    end
  end
end
