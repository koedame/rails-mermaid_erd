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

    it "opens the viewer with nothing selected and every column drawn" do
      expect(configuration.viewer_defaults).to eq({models: [], columns: "all"})
    end
  end

  context "when the config file exist" do
    before { copy_fixture("valid.yml") }
    after { remove_fixture }

    it "return overwrite config value" do
      expect(configuration.result_path).to eq("doc/erd.html")
      expect(configuration.ignore_tables).to eq(["\\Aaudit_", "\\Aschema_migrations\\z"])
      expect(configuration.viewer_defaults).to eq({models: %w[User Post], columns: "keys"})
    end
  end

  context "when viewer_defaults sets only columns" do
    before { copy_fixture("partial_viewer_defaults.yml") }
    after { remove_fixture }

    it "keeps the default for the other key" do
      expect(configuration.viewer_defaults).to eq({models: [], columns: "none"})
    end
  end

  context "when viewer_defaults is not a mapping" do
    before { copy_fixture("invalid_viewer_defaults.yml") }
    after { remove_fixture }

    it "raises ArgumentError naming the field and the offending value" do
      expect { configuration }.to raise_error(ArgumentError, /viewer_defaults.*mapping.*keys/m)
    end
  end

  context "when viewer_defaults has a key other than models and columns" do
    before { copy_fixture("unknown_viewer_defaults_key.yml") }
    after { remove_fixture }

    it "raises ArgumentError naming the unknown key instead of ignoring the typo" do
      expect { configuration }.to raise_error(ArgumentError, /unknown.*column\b/m)
    end
  end

  context "when viewer_defaults.columns is not one of all, keys, none" do
    before { copy_fixture("invalid_viewer_defaults_columns.yml") }
    after { remove_fixture }

    it "raises ArgumentError listing the accepted values" do
      expect { configuration }.to raise_error(ArgumentError, /columns.*all, keys, none.*compact/m)
    end
  end

  context "when viewer_defaults.models is not an array" do
    before { copy_fixture("invalid_viewer_defaults_models.yml") }
    after { remove_fixture }

    it "raises ArgumentError naming the field and the offending value" do
      expect { configuration }.to raise_error(ArgumentError, /viewer_defaults\.models.*User/m)
    end
  end

  context "when viewer_defaults.models contains an empty name" do
    before { copy_fixture("empty_name_viewer_defaults_models.yml") }
    after { remove_fixture }

    it "raises ArgumentError" do
      expect { configuration }.to raise_error(ArgumentError, /viewer_defaults\.models.*non-empty/m)
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
