module RailsMermaidErd
  # Registers the `mermaid_erd` rake task only when Rails is actually loading
  # tasks (i.e. under `rake`/`rails` CLIs, never on web/console/job boots).
  # Pairs with the `autoload` declarations in lib/rails-mermaid_erd.rb so the
  # heavy `Builder` / `Configuration` constants — and the `erb`/`fileutils`
  # requires their task body needs — stay off the boot path entirely.
  class Railtie < ::Rails::Railtie
    rake_tasks do
      load File.expand_path("../tasks/mermaid_erd.rake", __dir__)
    end
  end
end
