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
      # `safe_load` over `load` because this file is checked into the host
      # repo and may eventually be templated from CI inputs. Disallow custom
      # classes and aliases — the only legitimate value shapes here are
      # strings and arrays of strings.
      custom_config = YAML.safe_load(config_file.read, permitted_classes: [], aliases: false).symbolize_keys
      config = config.merge(custom_config)
    end

    @result_path = config[:result_path]
    @ignore_tables = normalize_ignore_tables(config[:ignore_tables])
  end

  private

  # Accept `nil` as "no patterns", reject anything that isn't an Array of
  # non-empty Strings. We validate eagerly so a malformed config surfaces a
  # clear ArgumentError at boot rather than a confusing `NoMethodError` deep
  # in `Builder.model_data`. The empty-string rejection in particular blocks
  # the silent footgun of `Regexp.new("")` matching every table.
  def normalize_ignore_tables(value)
    return [] if value.nil?

    unless value.is_a?(Array) && value.all? { |entry| entry.is_a?(String) && !entry.empty? }
      raise ArgumentError,
        "config/mermaid_erd.yml: `ignore_tables` must be an array of non-empty regex strings, got #{value.inspect}"
    end

    value
  end
end
