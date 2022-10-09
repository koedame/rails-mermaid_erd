require_relative "lib/rails-mermaid_erd/version"

Gem::Specification.new do |spec|
  spec.name = "rails-mermaid_erd"
  spec.version = RailsMermaidErd::VERSION
  spec.authors = ["肥溜め", "💩"]
  spec.email = []
  spec.homepage = "https://github.com/koedame/rails-mermaid_erd"
  spec.summary = "Generate Mermaid ERD for Ruby on Rails"
  spec.license = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "activerecord", ">= 4.2"
end
