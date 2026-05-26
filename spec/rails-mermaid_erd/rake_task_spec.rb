require "spec_helper"
require "rake"
require "stringio"

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

  # The front-end diagram builder must sanitise comment metadata the same way
  # the Ruby renderer (MermaidText) does, so a column/table comment containing
  # a `"` or a newline can't break the rendered diagram or the copied source.
  # Asserted at the source level (the JS runs in the browser), matching how the
  # other front-end behaviours in this file are pinned.
  it "escapes quotes and collapses newlines in the diagram source it builds" do
    expect(generated_html).to include("replace(/[\\r\\n]+/g, ' ')")
    expect(generated_html).to include("replace(/\"/g, '#quot;')")
  end

  # Issue #169 — performance contract for large schemas:
  describe "issue #169 performance hardening" do
    # The default `reset()` must not pre-select every model; otherwise opening
    # the page on a hundreds-of-models schema lays out the full diagram before
    # the user has any chance to narrow it down. We assert the behavioural
    # intent (empty default, no `Models.forEach` push) rather than a brittle
    # source-shape match.
    it "defaults the model selection to an empty list" do
      expect(generated_html).to include("selectModels.value = []")
      expect(generated_html).not_to match(/schemaData\.Models\.forEach\([^)]*\)\s*=>\s*\{\s*selectModels\.value\.push/)
    end

    # mermaid.initialize repeats theme + parser setup; doing it on every render
    # was wasted work. Confirm we now call it exactly once and that the call
    # precedes the reRender definition (i.e. lives at module level).
    it "initializes Mermaid exactly once at module level" do
      expect(generated_html.scan("mermaid.initialize(").count).to eq(1)
      init_offset = generated_html.index("mermaid.initialize(")
      re_render_offset = generated_html.index("const reRender = async")
      expect(init_offset).to be < re_render_offset
    end

    it "pins Mermaid securityLevel to strict and disables htmlLabels" do
      expect(generated_html).to include("securityLevel: 'strict'")
      expect(generated_html).to include("htmlLabels: false")
    end

    # Rapid toggles (multi-click on the sidebar, scrubbing options) must collapse
    # into a single render — otherwise back-to-back mermaid.render calls block
    # the main thread on large schemas. The hashchange handler must dispatch
    # via the debounced path, NOT call `reRender()` directly.
    it "debounces re-renders behind scheduleReRender" do
      expect(generated_html).to include("scheduleReRender")
      hashchange_listener = generated_html[/addEventListener\('hashchange',\s*\(\)\s*=>\s*\{[^}]*\}/m]
      expect(hashchange_listener).not_to be_nil
      expect(hashchange_listener).to include("scheduleReRender")
      expect(hashchange_listener).not_to match(/\breRender\(\)/)
    end

    # The opt-in snapshot mode replaces the SVG with a rasterised PNG for the
    # pan/zoom interaction — the biggest single win on Safari/Firefox.
    it "exposes an opt-in snapshot mode" do
      expect(generated_html).to include("isSnapshotMode")
      expect(generated_html).to include("snapshotDataUrl")
      expect(generated_html).to include("bakeSnapshot")
    end

    # Virtualisation keeps the sidebar DOM bounded for hundreds-of-models schemas.
    it "virtualises the sidebar model list above a threshold" do
      expect(generated_html).to include("isVirtualizingModels")
      expect(generated_html).to include("virtualListVisibleModels")
    end

    # Empty selection is the new default — both i18n locales must surface the
    # "pick a model" hint. CLAUDE.md keeps en/ja in sync explicitly, so this
    # guards against a translator drop.
    it "ships the empty-selection hint in both en and ja" do
      expect(generated_html).to include("No models selected")
      expect(generated_html).to include("モデルが選択されていません")
    end

    # Surfaced render failure: when Mermaid can't parse the diagram, the user
    # used to see a stale preview with no feedback. We now expose an i18n'd
    # banner. This locks both locales in place.
    it "ships the render-failure banner strings in both en and ja" do
      expect(generated_html).to include("Mermaid failed to render")
      expect(generated_html).to include("Mermaid の描画に失敗しました")
    end

    # I/O errors from FileUtils / File.write used to bubble up as raw
    # `Errno::EACCES` / `Errno::ENOSPC`, which left the user guessing which
    # config key controlled the path. Confirm the rescue re-raises with the
    # `result_path` hint instead.
    it "re-raises filesystem failures with an actionable hint" do
      tmp_path = Rails.root.join("tmp/mermaid_erd_io_spec.html")
      allow(RailsMermaidErd.configuration).to receive(:result_path).and_return(tmp_path.relative_path_from(Rails.root).to_s)
      # Force File.write to raise the kind of error users hit in production
      # (permission denied on read-only mounts, no space left on the volume).
      allow(File).to receive(:write).and_raise(Errno::EACCES.new(tmp_path.to_s))

      Rake::Task["mermaid_erd"].reenable
      expect { Rake::Task["mermaid_erd"].invoke }.to raise_error(/result_path/)
    end
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

describe "rake mermaid_erd:print" do
  before(:all) do
    Rake::Task.define_task(:environment) unless Rake::Task.task_defined?(:environment)
    Rails.application.load_tasks unless Rake::Task.task_defined?("mermaid_erd:print")
  end

  def run_print_task
    original = $stdout
    $stdout = StringIO.new
    Rake::Task["mermaid_erd:print"].reenable
    Rake::Task["mermaid_erd:print"].invoke
    $stdout.string
  ensure
    $stdout = original
  end

  it "prints the Mermaid erDiagram source for the dummy app to stdout" do
    output = run_print_task

    expect(output).to start_with("erDiagram\n")
    expect(output).to include('%% Generated by "Rails Mermaid ERD"')
    # The dummy app has an audit_logs table with an id PK — a stable anchor
    # that the model_data spec already pins.
    expect(output).to include("    AuditLog {")
    expect(output).to match(/^\s+integer id PK ""$/)
  end

  # The whole point of the task is a clean pipe: stdout must carry the diagram
  # and nothing else — no HTML viewer, and none of the migration-style logging
  # that Builder's schema introspection emits (which the task mutes). If the
  # mute regressed, the `foreign_keys(...)` log lines would land in `output`
  # and both the equality and the marker assertion would fail.
  it "emits only the diagram text, with no HTML or migration logging" do
    output = run_print_task
    diagram = RailsMermaidErd::MermaidText.build(RailsMermaidErd::Builder.model_data)

    # The task is `$stdout.puts diagram`, so output is the diagram with exactly
    # one trailing newline — asserted without depending on whether `build`
    # already ends in one (it does not when relations are present, does when
    # they are not).
    expect(output.chomp).to eq(diagram.chomp)
    expect(output).to end_with("\n")
    expect(output).not_to include("<html")
    expect(output).not_to include("SCHEMA_DATA")
    expect(output).not_to include("foreign_keys(")
  end

  # Muting migration logging flips a process-global; a failure mid-build must
  # not leak the muted state into later tasks in the same process.
  it "restores ActiveRecord::Migration.verbose even when model_data raises" do
    saved = ActiveRecord::Migration.verbose
    ActiveRecord::Migration.verbose = true
    allow(RailsMermaidErd::Builder).to receive(:model_data).and_raise(RuntimeError, "boom")

    Rake::Task["mermaid_erd:print"].reenable
    expect { Rake::Task["mermaid_erd:print"].invoke }.to raise_error(/boom/)
    expect(ActiveRecord::Migration.verbose).to be(true)
  ensure
    ActiveRecord::Migration.verbose = saved
  end
end
