require "yaml"

class RailsMermaidErd::Configuration
  attr_accessor :result_path
  attr_accessor :models_list
  attr_accessor :hide_columns

  def initialize(config_file)
    config_file = config_file || "config/mermaid_erd.yml"
    config = {
      result_path: "mermaid_erd/index.html",
      models_list: "::ActiveRecord::Base.descendants.sort_by(&:name)",
      hide_columns: false
    }
    puts "config_file: #{config_file}"
    config_file = Rails.root.join(config_file)

    if File.exist?(config_file)
      custom_config = YAML.load(config_file.read).symbolize_keys
      config = config.merge(custom_config)
    end

    @result_path = config[:result_path]
    @models_list = config[:models_list]
    @hide_columns = config[:hide_columns]
    puts "models_list: #{@models_list}"
  end
end
