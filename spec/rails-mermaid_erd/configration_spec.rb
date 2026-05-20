require "spec_helper"

describe RailsMermaidErd::Configuration do
  let(:configuration) { RailsMermaidErd::Configuration.new }

  def copy_fixture(name)
    FileUtils.cp(file_fixture("configurations/#{name}").to_s, Rails.root.join("config/mermaid_erd.yml").to_s)
  end

  def remove_fixture
    FileUtils.rm(Rails.root.join("config/mermaid_erd.yml").to_s)
  end

  context "when the config file does not exist" do
    it "return default config value" do
      expect(configuration.result_path).to eq("mermaid_erd/index.html")
      expect(configuration.ignore_tables).to eq([])
    end
  end

  context "when the config file exist" do
    before { copy_fixture("valid.yml") }
    after { remove_fixture }

    it "return overwrite config value" do
      expect(configuration.result_path).to eq("doc/erd.html")
      expect(configuration.ignore_tables).to eq(["\\Aaudit_", "\\Aschema_migrations\\z"])
    end
  end

  context "when ignore_tables is set to a non-array value" do
    before { copy_fixture("invalid_ignore_tables.yml") }
    after { remove_fixture }

    it "raises ArgumentError naming the field and the offending value" do
      expect { configuration }.to raise_error(ArgumentError, /ignore_tables.*not_an_array/m)
    end
  end

  context "when ignore_tables contains a non-string entry" do
    before { copy_fixture("non_string_ignore_tables.yml") }
    after { remove_fixture }

    it "raises ArgumentError" do
      expect { configuration }.to raise_error(ArgumentError, /ignore_tables/)
    end
  end

  context "when ignore_tables contains an empty-string pattern" do
    before { copy_fixture("empty_pattern_ignore_tables.yml") }
    after { remove_fixture }

    it "raises ArgumentError to block the `Regexp.new(\"\")` matches-everything footgun" do
      expect { configuration }.to raise_error(ArgumentError, /non-empty/)
    end
  end

  context "when the config file contains a disallowed YAML class" do
    before { copy_fixture("unsafe_yaml.yml") }
    after { remove_fixture }

    it "raises Psych::DisallowedClass so a tampered file fails loudly" do
      expect { configuration }.to raise_error(Psych::DisallowedClass)
    end
  end
end
