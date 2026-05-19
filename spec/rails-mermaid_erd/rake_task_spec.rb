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

  # Regression guard: a table/column comment containing `</script>` must not
  # close the SCHEMA_DATA script tag early. ActiveSupport's default JSON
  # encoder escapes `<` and `>` as `<`/`>` (controlled by
  # `ActiveSupport::JSON::Encoding.escape_html_entities_in_json`), so the
  # hostile bytes never reach the rendered HTML. This test drives the
  # actual rake task with hostile data so a future Rails change that flips
  # that default would fail here instead of shipping a broken ERD.
  it "renders SCHEMA_DATA safely when host-app metadata contains </script>" do
    hostile = {
      Models: [{
        TableName: "evil",
        TableComment: "</script><script>alert(1)</script>",
        ModelName: "Evil",
        IsModelExist: true,
        Columns: [{name: "id", type: :integer, key: "PK", comment: nil}]
      }],
      Relations: []
    }
    tmp_path = Rails.root.join("tmp/mermaid_erd_escape_spec.html")
    FileUtils.mkdir_p(File.dirname(tmp_path))

    allow(RailsMermaidErd::Builder).to receive(:model_data).and_return(hostile)
    allow(RailsMermaidErd.configuration).to receive(:result_path).and_return(tmp_path.relative_path_from(Rails.root).to_s)

    Rake::Task["mermaid_erd"].reenable
    Rake::Task["mermaid_erd"].invoke

    # Slice the bytes between `window.SCHEMA_DATA=` and the next literal
    # `</script>`. If hostile bytes reach the page unescaped, the first
    # `</script>` lands inside the JSON, `payload` is truncated, and
    # `JSON.parse` raises.
    payload = File.read(tmp_path)[/window\.SCHEMA_DATA=(.*?)<\/script>/m, 1]
    expect(payload).not_to be_nil
    expect(JSON.parse(payload)).to eq(JSON.parse(hostile.to_json))
  ensure
    FileUtils.rm_f(tmp_path) if tmp_path
  end
end
