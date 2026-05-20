require "spec_helper"
require "base64"
require "json"
require "tempfile"

SCRIPT_PATH = File.expand_path("../../script/release_screenshot_hash.rb", __dir__)

def run_script(input)
  Tempfile.create(["schema", ".html"]) do |f|
    f.write(input)
    f.flush
    out = `ruby #{SCRIPT_PATH.shellescape} #{f.path.shellescape} 2>&1`
    [out, $?.success?]
  end
end

def schema_html(models)
  schema = {"Models" => models, "Relations" => []}
  %(<html><body><script>window.SCHEMA_DATA=#{schema.to_json}</script></body></html>)
end

describe "script/release_screenshot_hash.rb" do
  it "emits a base64 hash containing every model name" do
    html = schema_html([
      {"ModelName" => "Post", "TableName" => "posts", "Columns" => []},
      {"ModelName" => "Tag", "TableName" => "tags", "Columns" => []}
    ])
    out, ok = run_script(html)
    expect(ok).to be(true), out
    expect(JSON.parse(Base64.strict_decode64(out))).to eq("selectModels" => ["Post", "Tag"])
  end

  it "survives a TableComment containing literal `}</script>`" do
    # Reproduces the failure mode the brace-walker exists to handle: Ruby's
    # to_json does not escape `</script>` inside string values, so a naive
    # `\{.*?\}\s*<\/script>` regex would truncate mid-string.
    html = schema_html([
      {"ModelName" => "Post", "TableName" => "posts", "TableComment" => "user wrote: }</script>", "Columns" => []},
      {"ModelName" => "Tag", "TableName" => "tags", "Columns" => []}
    ])
    out, ok = run_script(html)
    expect(ok).to be(true), out
    expect(JSON.parse(Base64.strict_decode64(out))).to eq("selectModels" => ["Post", "Tag"])
  end

  it "respects escaped quotes inside JSON strings" do
    html = schema_html([
      {"ModelName" => "Post", "TableName" => "posts", "TableComment" => %(a "quoted" }), "Columns" => []}
    ])
    out, ok = run_script(html)
    expect(ok).to be(true), out
    expect(JSON.parse(Base64.strict_decode64(out))).to eq("selectModels" => ["Post"])
  end

  it "fails loudly when Models is empty (refuses to commit a blank screenshot)" do
    out, ok = run_script(schema_html([]))
    expect(ok).to be(false)
    expect(out).to include("no models found")
  end

  it "fails when SCHEMA_DATA is missing" do
    out, ok = run_script("<html><body>no schema here</body></html>")
    expect(ok).to be(false)
    expect(out).to include("SCHEMA_DATA assignment not found")
  end
end
