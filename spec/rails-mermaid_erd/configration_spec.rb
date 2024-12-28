require "spec_helper"

describe RailsMermaidErd::Configuration do
  let(:configuration) { RailsMermaidErd::Configuration.new }

  context "when the config file does not exist" do
    it "return default config value" do
      expect(configuration.result_path).to eq("mermaid_erd/index.html")
      expect(configuration.all_models_selected).to eq(true)
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
      expect(configuration.all_models_selected).to eq(false)
    end
  end
end
