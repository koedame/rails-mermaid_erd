require "spec_helper"

# Not every Rails application backs its associations with foreign key
# constraints, so a column is a key when an association names it, not only when
# the database says so.
describe RailsMermaidErd::Builder do
  describe ".model_data key columns" do
    let(:result) { described_class.model_data }

    def keys_of(model_name)
      model = result[:Models].find { |m| m[:ModelName] == model_name }
      model[:Columns].to_h { |column| [column[:name], column[:key]] }
    end

    it "marks the column a `belongs_to` names as a foreign key when no constraint backs it" do
      expect(ActiveRecord::Schema.foreign_keys("bookmarks")).to be_empty
      expect(keys_of("Bookmark")).to include("post_id" => "FK", "reader_id" => "FK")
    end

    it "marks the column a `has_many` names on the other table as a foreign key when nothing there names it" do
      expect(ActiveRecord::Schema.foreign_keys("notes")).to be_empty
      expect(keys_of("Note")).to include("post_id" => "FK")
    end

    it "marks the id column of a polymorphic `belongs_to`, and leaves its type column alone" do
      expect(keys_of("MatchingInfoCareType")).to include("matching_info_id" => "FK", "matching_info_type" => "")
    end

    it "marks a foreign key column that a constraint backs and no association names" do
      expect(keys_of("Comment")).to include("user_id" => "FK")
    end

    it "leaves columns no association names as they are" do
      expect(keys_of("Bookmark")).to include("created_at" => "", "updated_at" => "")
    end

    if ActiveRecord.version >= Gem::Version.new("7.1")
      it "marks every column of a composite primary key" do
        expect(keys_of("Membership")).to include("organization_code" => "PK", "member_code" => "PK", "role" => "")
      end
    end

    context "when the table a `belongs_to` points at is ignored" do
      around do |example|
        original = RailsMermaidErd.configuration.ignore_tables
        RailsMermaidErd.configuration.ignore_tables = ["\\Aposts\\z"]
        example.run
      ensure
        RailsMermaidErd.configuration.ignore_tables = original
      end

      it "still marks the column as a foreign key" do
        expect(keys_of("Bookmark")).to include("post_id" => "FK")
      end
    end
  end
end
