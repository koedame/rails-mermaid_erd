require "erb"
require "fileutils"

desc "Generate Mermaid ERD."
task mermaid_erd: :environment do
  result = RailsMermaidErd::Builder.model_data

  version = RailsMermaidErd::VERSION
  app_name = ::Rails.application.class.try(:parent_name) || ::Rails.application.class.try(:module_parent_name)
  logo = RailsMermaidErd.read_gem_asset("./assets/logo.svg")
  tailwindcss_js = RailsMermaidErd.read_gem_asset("./templates/vendor/tailwindcss.js")
  mermaid_js = RailsMermaidErd.read_gem_asset("./templates/vendor/mermaid.min.js")
  vue_js = RailsMermaidErd.read_gem_asset("./templates/vendor/vue.global.prod.min.js")
  erb = ERB.new(RailsMermaidErd.read_gem_asset("./templates/index.html.erb"))
  result_html = erb.result(binding)

  result_dir = ::Rails.root.join(File.dirname(RailsMermaidErd.configuration.result_path))
  FileUtils.mkdir_p(result_dir)

  result_file = ::Rails.root.join(RailsMermaidErd.configuration.result_path)
  File.write(result_file, result_html)
end
