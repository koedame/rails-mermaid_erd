require "spec_helper"
require "rake"

# Issue #169: Bundler auto-requires the gem on every Rails boot. The rake task
# definition needs to stay off the boot path so web, console, and job processes
# don't pay for `Builder`, `Configuration`, `erb`, `fileutils`, or the rake
# runtime just to keep a task reachable.
describe RailsMermaidErd::Railtie do
  it "is a Rails::Railtie" do
    expect(described_class.ancestors).to include(::Rails::Railtie)
  end

  it "registers the mermaid_erd task behind rake_tasks" do
    # `@rake_tasks` is the Railtie's own internal store; presence here proves
    # the task is registered lazily (it only runs when `Rails.application
    # .load_tasks` walks these blocks), not at `require` time.
    rake_blocks = described_class.instance_variable_get(:@rake_tasks)
    expect(rake_blocks).to be_a(Array)
    expect(rake_blocks).not_to be_empty
  end

  it "loads the bundled tasks file when its rake_tasks block runs" do
    # Defence in depth: the block being present is meaningless if the path it
    # loads is wrong. Calling the block in isolation proves we ship the file
    # we claim to ship — if a future refactor renames lib/tasks/mermaid_erd.rake
    # without updating the railtie, this catches it.
    rake_blocks = described_class.instance_variable_get(:@rake_tasks)
    expect { rake_blocks.first.call }.not_to raise_error
    expect(Rake::Task.task_defined?("mermaid_erd")).to be true
  end
end

describe "boot-time lazy loading (issue #169)" do
  # The top-level entry point must not pull in Builder, Configuration, ERB, or
  # FileUtils — they cost work the host's `rails s` / `rails c` / `sidekiq`
  # boots should never pay for. Inspecting source is the only durable check
  # because earlier specs in the suite will have already autoloaded these
  # constants, so a runtime check would always pass spuriously.
  it "does not eagerly require Builder or Configuration from the top-level file" do
    source = File.read(File.expand_path("../../lib/rails-mermaid_erd.rb", __dir__))
    expect(source).not_to match(/^require(_relative)?\s+["']rails-mermaid_erd\/builder["']/)
    expect(source).not_to match(/^require(_relative)?\s+["']rails-mermaid_erd\/configuration["']/)
  end

  it "does not require erb or fileutils from the top-level file" do
    source = File.read(File.expand_path("../../lib/rails-mermaid_erd.rb", __dir__))
    expect(source).not_to match(/^require\s+["']erb["']/)
    expect(source).not_to match(/^require\s+["']fileutils["']/)
  end

  it "does not extend Rake::DSL" do
    source = File.read(File.expand_path("../../lib/rails-mermaid_erd.rb", __dir__))
    expect(source).not_to include("extend Rake::DSL")
    expect(source).not_to match(/^require\s+["']rake["']/)
  end

  it "keeps Builder and Configuration reachable via autoload" do
    # The constants must still resolve so the rake task — and any host-app
    # code that opts in — can use them.
    expect { RailsMermaidErd::Builder }.not_to raise_error
    expect { RailsMermaidErd::Configuration }.not_to raise_error
  end
end
