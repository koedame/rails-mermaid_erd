require "yaml"

class RailsMermaidErd::Configuration
  attr_accessor :result_path, :ignore_tables

  DEFAULTS = {
    result_path: "mermaid_erd/index.html",
    ignore_tables: []
  }.freeze

  def initialize
    config = DEFAULTS.dup

    config_file = Rails.root.join("config/mermaid_erd.yml")
    if File.exist?(config_file)
      custom_config = YAML.load(config_file.read).symbolize_keys
      config = config.merge(custom_config)
    end

    @result_path = config[:result_path]
    @ignore_tables = normalize_ignore_tables(config[:ignore_tables])
  end

  private

  # Accept `nil` as "no patterns", reject anything that isn't an Array of
  # Strings. We validate eagerly so a malformed config surfaces a clear
  # ArgumentError at boot rather than a confusing `NoMethodError` deep in
  # `Builder.model_data`.
  def normalize_ignore_tables(value)
    return [] if value.nil?

    unless value.is_a?(Array) && value.all? { |entry| entry.is_a?(String) }
      raise ArgumentError,
        "config/mermaid_erd.yml: `ignore_tables` must be an array of regex strings, got #{value.inspect}"
    end

    value
  end
end
