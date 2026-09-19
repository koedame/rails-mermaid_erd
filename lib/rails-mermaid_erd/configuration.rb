require "yaml"

class RailsMermaidErd::Configuration
  attr_accessor :result_path, :ignore_tables, :viewer_defaults

  # Mirrors the Columns choice in the viewer's sidebar.
  VIEWER_COLUMNS = %w[all keys none].freeze

  DEFAULTS = {
    result_path: "mermaid_erd/index.html",
    ignore_tables: [],
    viewer_defaults: {}
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
    @viewer_defaults = normalize_viewer_defaults(config[:viewer_defaults])
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

  # The two keys are read one by one rather than merged over a default hash,
  # so setting only `columns` leaves `models` at its default. Unknown keys are
  # rejected because a typo such as `column: keys` would otherwise be dropped
  # without a trace and the viewer would open the way it always did.
  def normalize_viewer_defaults(value)
    value = {} if value.nil?

    unless value.is_a?(Hash)
      raise ArgumentError,
        "config/mermaid_erd.yml: `viewer_defaults` must be a mapping with `models` and/or `columns`, got #{value.inspect}"
    end

    unknown = value.keys.map(&:to_s) - %w[models columns]
    unless unknown.empty?
      raise ArgumentError,
        "config/mermaid_erd.yml: unknown `viewer_defaults` key(s) #{unknown.join(", ")}; use `models` and/or `columns`"
    end

    value = value.transform_keys(&:to_s)
    {
      models: normalize_viewer_models(value["models"]),
      columns: normalize_viewer_columns(value["columns"])
    }
  end

  def normalize_viewer_models(value)
    return [] if value.nil?

    unless value.is_a?(Array) && value.all? { |entry| entry.is_a?(String) && !entry.empty? }
      raise ArgumentError,
        "config/mermaid_erd.yml: `viewer_defaults.models` must be an array of non-empty model names, got #{value.inspect}"
    end

    value.uniq
  end

  def normalize_viewer_columns(value)
    return "all" if value.nil?

    unless VIEWER_COLUMNS.include?(value)
      raise ArgumentError,
        "config/mermaid_erd.yml: `viewer_defaults.columns` must be one of #{VIEWER_COLUMNS.join(", ")}, got #{value.inspect}"
    end

    value
  end
end
