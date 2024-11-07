require "yaml"

class RailsMermaidErd::Configuration
  attr_accessor :result_path
  attr_accessor :models_list

  def initialize
    config = {
      result_path: "mermaid_erd/index.html",
      models_list: "::ActiveRecord::Base.descendants.sort_by(&:name)"
    }

    config_file = Rails.root.join("config/mermaid_erd.yml")
    if File.exist?(config_file)
      custom_config = YAML.load(config_file.read).symbolize_keys
      config = config.merge(custom_config)
    end

    @result_path = config[:result_path]
    @models_list = config[:models_list]
  end
end
