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
      @configuration ||= RailsMermaidErd::Configuration.new(ENV['CONFIG_FILE'] )
    end
  end

  desc "Generate Mermaid ERD."
  task mermaid_erd: :environment do
    result = RailsMermaidErd::Builder.model_data

    version = VERSION
    app_name = ::Rails.application.class.try(:parent_name) || ::Rails.application.class.try(:module_parent_name)
    logo = File.read(File.expand_path("./assets/logo.svg", __dir__))
    erb = ERB.new(File.read(File.expand_path("./templates/index.html.erb", __dir__)))
    result_html = erb.result(binding)

    result_dir = Rails.root.join(File.dirname(RailsMermaidErd.configuration.result_path))
    FileUtils.mkdir_p(result_dir)

    result_file = Rails.root.join(RailsMermaidErd.configuration.result_path)
    File.write(result_file, result_html)
  end
end
