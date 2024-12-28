require "yaml"

class RailsMermaidErd::Configuration
  attr_accessor :result_path, :ignore

  def initialize
    config = {
      result_path: "mermaid_erd/index.html",
      ignore: []
    }

    config_file = Rails.root.join("config/mermaid_erd.yml")
    if File.exist?(config_file)
      custom_config = YAML.load(config_file.read).symbolize_keys
      config = config.merge(custom_config)
    end

    @result_path = config[:result_path]
    @ignore = config[:ignore]
  end
end
