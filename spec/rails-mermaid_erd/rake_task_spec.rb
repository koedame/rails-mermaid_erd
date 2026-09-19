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

  # The viewer draws whatever SCHEMA_DATA lists, so a single table inheritance
  # subclass must not reach it as a model or a relation endpoint.
  it "hands the viewer a single table inheritance hierarchy as one model" do
    payload = generated_html[%r{<script>window\.SCHEMA_DATA=(.*?)</script>}m, 1]
    schema = JSON.parse(payload)
    model_names = schema["Models"].map { |m| m["ModelName"] }
    endpoints = schema["Relations"].flat_map { |r| [r["LeftModelName"], r["RightModelName"]] }

    expect(model_names.count("Comment")).to eq(1)
    expect(model_names + endpoints).not_to include("Complaint")
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
    # source-shape match. `reset()` starts from the `viewer_defaults` the task
    # hands over, so an app that configures nothing must be handed an empty list.
    it "defaults the model selection to an empty list" do
      handed_over = JSON.parse(generated_html[%r{<script>window\.VIEWER_DEFAULTS=(.*?)</script>}m, 1])
      expect(handed_over["models"]).to eq([])
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

    # Every supported locale must carry a full translation block. A missing
    # locale would make i18n[language][...] return undefined at runtime, so we
    # assert one signature string (the empty-selection title) per locale to
    # catch a dropped or garbled block.
    it "ships the empty-selection title for every supported locale" do
      {
        "en" => "No models selected",
        "ja" => "モデルが選択されていません",
        "zh-CN" => "未选择模型",
        "zh-TW" => "尚未選擇模型",
        "ko" => "선택된 모델이 없습니다",
        "es" => "Ningún modelo seleccionado",
        "fr" => "Aucun modèle sélectionné",
        "de" => "Keine Modelle ausgewählt",
        "it" => "Nessun modello selezionato",
        "pt-BR" => "Nenhum modelo selecionado",
        "ru" => "Модели не выбраны",
        "ar" => "لم يتم تحديد أي نموذج"
      }.each do |locale, title|
        expect(generated_html).to include(title), "missing empty-selection title for #{locale}"
      end
    end

    # The language selector is generated from window.locales, which also drives
    # the document `dir` switch. Confirm the metadata ships every code and that
    # Arabic is flagged right-to-left.
    it "registers every locale in the selector metadata with the Arabic RTL flag" do
      %w[en ja zh-CN zh-TW ko es fr de it pt-BR ru ar].each do |code|
        expect(generated_html).to include("{ code: '#{code}'"), "missing locale metadata for #{code}"
      end
      expect(generated_html).to include("code: 'ar', label: 'العربية', dir: 'rtl'")
    end

    # The viewer reads every string as i18n[language][section][key] — a chained
    # bracket access that silently yields the literal "undefined" if any key is
    # missing from a locale. The per-locale title check above only proves one
    # key exists; this locks the real invariant: every locale carries exactly
    # the same key structure as en, and window.locales stays in sync with
    # window.i18n so no selectable locale can resolve to an absent block.
    it "ships an identical i18n key structure for every supported locale" do
      block = generated_html[/window\.i18n = \{\n(.*?)\n    \}\n  <\/script>/m, 1]
      expect(block).not_to be_nil, "could not locate the window.i18n block"

      locales = {}
      block.split(/\n      (?=(?:'[\w-]+'|[a-z]{2}): \{)/).each do |segment|
        code = segment[/\A\s*('?[\w-]+'?): \{/, 1]&.delete("'")
        next unless code
        locales[code] = segment.scan(/^\s{8}(\w+): \{(.*?)\n\s{8}\}/m).flat_map do |section, body|
          body.scan(/^\s{10}(\w+):/).flatten.map { |key| "#{section}.#{key}" }
        end.sort
      end

      expect(locales.keys).to match_array(%w[en ja zh-CN zh-TW ko es fr de it pt-BR ru ar])

      # window.locales codes must match the i18n locale keys exactly, otherwise a
      # selectable code could key into a non-existent block.
      metadata_codes = generated_html.scan(/\{ code: '([\w-]+)'/).flatten
      expect(metadata_codes).to match_array(locales.keys)

      en_paths = locales.fetch("en")
      expect(en_paths).not_to be_empty
      locales.each do |code, paths|
        expect(paths).to eq(en_paths),
          "locale '#{code}' i18n keys differ from en (missing: #{(en_paths - paths).inspect}, extra: #{(paths - en_paths).inspect})"
      end
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

describe "rake mermaid_erd viewer defaults" do
  let(:tmp_path) { Rails.root.join("tmp/mermaid_erd_viewer_defaults_spec.html") }

  let(:schema) do
    {
      Models: %w[User Post].map do |name|
        {TableName: name.downcase, TableComment: nil, ModelName: name, IsModelExist: true, Columns: [{name: "id", type: :integer, key: "PK", comment: nil}]}
      end,
      Relations: []
    }
  end

  before do
    Rake::Task.define_task(:environment) unless Rake::Task.task_defined?(:environment)
    Rails.application.load_tasks unless Rake::Task.task_defined?("mermaid_erd")
    FileUtils.mkdir_p(File.dirname(tmp_path))
    allow(RailsMermaidErd::Builder).to receive(:model_data).and_return(schema)
    allow(RailsMermaidErd.configuration).to receive(:result_path).and_return(tmp_path.relative_path_from(Rails.root).to_s)
    allow(RailsMermaidErd.configuration).to receive(:viewer_defaults).and_return(configured)
  end

  after { FileUtils.rm_f(tmp_path) }

  def generate
    Rake::Task["mermaid_erd"].reenable
    Rake::Task["mermaid_erd"].invoke
  end

  def hand_over
    JSON.parse(File.read(tmp_path)[%r{<script>window\.VIEWER_DEFAULTS=(.*?)</script>}m, 1])
  end

  context "when every listed model is in the diagram" do
    let(:configured) { {models: %w[Post], columns: "keys"} }

    it "hands the viewer the configured defaults without a warning" do
      expect { generate }.not_to output.to_stderr

      expect(hand_over).to eq({"models" => %w[Post], "columns" => "keys"})
    end
  end

  context "when a listed model is not in the diagram" do
    let(:configured) { {models: %w[Post Ghost], columns: "all"} }

    it "warns naming the model and leaves it out of the preselection" do
      expect { generate }.to output(/viewer_defaults\.models.*Ghost, which is not in the diagram/m).to_stderr

      expect(hand_over).to eq({"models" => %w[Post], "columns" => "all"})
    end
  end

  context "when several listed models are not in the diagram" do
    let(:configured) { {models: %w[Ghost Phantom], columns: "all"} }

    it "warns naming all of them" do
      expect { generate }.to output(/Ghost, Phantom, which are not in the diagram/).to_stderr

      expect(hand_over).to eq({"models" => [], "columns" => "all"})
    end
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

  # `Complaint < Comment` shares the `comments` table, so the dump must draw
  # that table once and never name the subclass.
  it "prints a single table inheritance hierarchy as one entity" do
    output = run_print_task

    expect(output.scan(/^    Comment \{$/).size).to eq(1)
    expect(output).not_to match(/\bComplaint\b/)
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
