require "spec_helper"
require "rake"

describe "rake mermaid_erd" do
  let(:output_path) { Rails.root.join("mermaid_erd/index.html") }

  before(:all) do
    # Rails is already booted via spec_helper, so the :environment prereq is
    # only needed for the rake DSL — stub it with a no-op if it isn't defined.
    Rake::Task.define_task(:environment) unless Rake::Task.task_defined?(:environment)
    Rails.application.load_tasks unless Rake::Task.task_defined?("mermaid_erd")
    Rake::Task["mermaid_erd"].reenable
    Rake::Task["mermaid_erd"].invoke
  end

  let(:generated_html) { File.read(output_path) }

  it "writes the ERD to the configured result path" do
    expect(File).to exist(output_path)
    expect(File.size(output_path)).to be > 1_000_000 # vendored bundles ~1.6MB
  end

  # Regression guard for issue #85: every front-end dependency must be
  # inlined so the generated HTML works offline and is unaffected by
  # upstream CDN outages.
  it "does not reference any external CDN" do
    %w[
      https://cdn.tailwindcss.com
      https://cdnjs.cloudflare.com
      https://unpkg.com
      https://cdn.jsdelivr.net
    ].each do |cdn|
      expect(generated_html).not_to include(cdn),
        "generated HTML still references #{cdn}; inlining must cover every script"
    end
  end

  it "inlines Tailwind, Mermaid, and Vue bundles" do
    # Tailwind Play CDN bundle is an IIFE prelude.
    expect(generated_html).to include("__esbuild_esm_mermaid_nm") # Mermaid 11.x bundle marker
    expect(generated_html).to include('globalThis["mermaid"]')    # Mermaid exposes itself globally
    expect(generated_html).to match(/var Vue\s*=/)                # Vue 3 global build
  end
end
