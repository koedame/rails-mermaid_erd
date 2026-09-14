require "erb"
require "fileutils"
# Explicit `require_relative` rather than leaning on the module's `autoload`:
# if the gem install is broken (e.g. lib/rails-mermaid_erd/builder.rb pruned),
# we want a LoadError with the missing path here — not a NameError raised
# deep inside the task body where the cause is harder to diagnose.
require_relative "../rails-mermaid_erd/builder"
require_relative "../rails-mermaid_erd/configuration"
require_relative "../rails-mermaid_erd/mermaid_text"

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

  result_file = ::Rails.root.join(RailsMermaidErd.configuration.result_path)
  result_dir = result_file.dirname

  # Re-raise filesystem failures with an actionable hint pointing at the
  # `result_path` config key, mirroring the friendly error in
  # `RailsMermaidErd.read_gem_asset`. Without this the user just sees a raw
  # `Errno::EACCES` / `Errno::ENOSPC` and has to guess which knob controls it.
  begin
    FileUtils.mkdir_p(result_dir)
    File.write(result_file, result_html)
  rescue SystemCallError => e
    raise "rails-mermaid_erd: could not write ERD to #{result_file} (#{e.class}: #{e.message}). " \
          "Check the `result_path` key in config/mermaid_erd.yml and that the directory is writable."
  end
end

namespace :mermaid_erd do
  desc "Print Mermaid ERD source to stdout."
  task print: :environment do
    # Builder calls `ActiveRecord::Schema.foreign_keys`, whose migration-style
    # `-- foreign_keys(...)` / `-> 0.001s` logging would otherwise land on
    # stdout and corrupt the piped diagram. Mute it just for the build, and
    # restore it in `ensure` so an error mid-build can't leak the muted global
    # into later tasks running in the same process.
    was_verbose = ActiveRecord::Migration.verbose
    ActiveRecord::Migration.verbose = false
    result =
      begin
        RailsMermaidErd::Builder.model_data
      ensure
        ActiveRecord::Migration.verbose = was_verbose
      end

    # Stream the raw `erDiagram` text to stdout so it pipes into other tools
    # (`> er.mmd`, `| mmdc -i - -o er.svg`) without writing the HTML viewer.
    $stdout.puts RailsMermaidErd::MermaidText.build(result)
  end
end
