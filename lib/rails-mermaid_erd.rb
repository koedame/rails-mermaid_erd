require_relative "rails-mermaid_erd/version"

module RailsMermaidErd
  # Resolve `Builder` and `Configuration` lazily so requiring this file from
  # Bundler's auto-require on every Rails boot (web, console, jobs) only pays
  # for the Railtie declaration below. The actual classes — plus their
  # transitive `yaml` require — load on first reference, which in practice
  # means "when the rake task runs."
  autoload :Builder, "rails-mermaid_erd/builder"
  autoload :Configuration, "rails-mermaid_erd/configuration"

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    # File.read with a domain-specific error when the bundled asset is missing,
    # which usually means a broken gem install (e.g. lib/templates/vendor/ got
    # pruned). The default Errno::ENOENT just points at this file and is hard
    # to act on.
    def read_gem_asset(relative_path)
      path = File.expand_path(relative_path, __dir__)
      File.read(path)
    rescue Errno::ENOENT
      raise "rails-mermaid_erd: bundled asset missing at #{path}. " \
            "The gem appears to be incompletely installed; " \
            "try `gem pristine rails-mermaid_erd` or reinstall the gem."
    end
  end
end

require_relative "rails-mermaid_erd/railtie" if defined?(Rails::Railtie)
