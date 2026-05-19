require "spec_helper"

describe RailsMermaidErd::Configuration do
  let(:configuration) { RailsMermaidErd::Configuration.new }

  context "when the config file does not exist" do
    it "return default config value" do
      expect(configuration.result_path).to eq("mermaid_erd/index.html")
      expect(configuration.ignore_tables).to eq([])
    end
  end

  context "when the config file exist" do
    before do
      FileUtils.cp(file_fixture("configurations/valid.yml").to_s, Rails.root.join("config/mermaid_erd.yml").to_s)
    end
    after do
      FileUtils.rm(Rails.root.join("config/mermaid_erd.yml").to_s)
    end
    it "return overwrite config value" do
      expect(configuration.result_path).to eq("doc/erd.html")
      expect(configuration.ignore_tables).to eq(["\\Aaudit_", "\\Aschema_migrations\\z"])
    end
  end

  context "when ignore_tables is set to a non-array value" do
    before do
      FileUtils.cp(file_fixture("configurations/invalid_ignore_tables.yml").to_s, Rails.root.join("config/mermaid_erd.yml").to_s)
    end
    after do
      FileUtils.rm(Rails.root.join("config/mermaid_erd.yml").to_s)
    end
    it "raises ArgumentError with a helpful message" do
      expect { configuration }.to raise_error(ArgumentError, /ignore_tables/)
    end
  end
end
