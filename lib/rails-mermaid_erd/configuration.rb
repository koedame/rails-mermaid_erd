require "yaml"

class RailsMermaidErd::Configuration
  attr_accessor :result_path, :all_models_selected

  def initialize
    config = {
      result_path: "mermaid_erd/index.html",
      all_models_selected: true,
    }

    config_file = Rails.root.join("config/mermaid_erd.yml")
    if File.exist?(config_file)
      custom_config = YAML.load(config_file.read).symbolize_keys
      config = config.merge(custom_config)
    end

    @all_models_selected = config[:all_models_selected]
    @result_path = config[:result_path]
  end

  def to_json
    {
      allModelsSelected: @all_models_selected,
      resultPath: @result_path
    }.to_json
  end
end
