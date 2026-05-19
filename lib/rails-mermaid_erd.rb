require "erb"
require "fileutils"
require "rake"
require "rake/dsl_definition"
require_relative "rails-mermaid_erd/version"
require_relative "rails-mermaid_erd/configuration"
require_relative "rails-mermaid_erd/builder"

module RailsMermaidErd
  extend Rake::DSL

  class << self
    def configuration
      @configuration ||= RailsMermaidErd::Configuration.new
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

  desc "Generate Mermaid ERD."
  task mermaid_erd: :environment do
    result = RailsMermaidErd::Builder.model_data

    version = VERSION
    app_name = ::Rails.application.class.try(:parent_name) || ::Rails.application.class.try(:module_parent_name)
    logo = RailsMermaidErd.read_gem_asset("./assets/logo.svg")
    tailwindcss_js = RailsMermaidErd.read_gem_asset("./templates/vendor/tailwindcss.js")
    mermaid_js = RailsMermaidErd.read_gem_asset("./templates/vendor/mermaid.min.js")
    vue_js = RailsMermaidErd.read_gem_asset("./templates/vendor/vue.global.prod.min.js")
    erb = ERB.new(RailsMermaidErd.read_gem_asset("./templates/index.html.erb"))
    result_html = erb.result(binding)

    result_dir = Rails.root.join(File.dirname(RailsMermaidErd.configuration.result_path))
    FileUtils.mkdir_p(result_dir)

    result_file = Rails.root.join(RailsMermaidErd.configuration.result_path)
    File.write(result_file, result_html)
  end
end
