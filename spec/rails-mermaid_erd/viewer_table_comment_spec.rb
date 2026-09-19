require "spec_helper"
require "rake"
require "ferrum"
require "json"
require "base64"

# What a heading reads is only observable in a real browser: the option is
# applied while Vue builds the Mermaid source, and Mermaid renders it
# asynchronously. These examples tick the option the way a user does and read
# the headings out of the rendered SVG.
describe "generated viewer table comment display" do
  let(:output_path) { Rails.root.join("tmp/mermaid_erd_table_comment_spec.html") }

  let(:schema) do
    {
      Models: [
        {
          TableName: "users", TableComment: "ユーザー", ModelName: "User", IsModelExist: true,
          Columns: [{name: "id", type: :integer, key: "PK", comment: nil}]
        },
        {
          TableName: "posts", TableComment: "", ModelName: "Post", IsModelExist: true,
          Columns: [{name: "id", type: :integer, key: "PK", comment: nil}]
        },
        {
          TableName: "tags", TableComment: %(tag "kind"\nsecond line), ModelName: "Tag", IsModelExist: true,
          Columns: [{name: "id", type: :integer, key: "PK", comment: nil}]
        }
      ],
      Relations: [
        {LeftModelName: "User", LeftValue: "||", Line: "--", RightValue: "o{", RightModelName: "Post", Comment: "User has_many posts"}
      ]
    }
  end

  before(:all) do
    Rake::Task.define_task(:environment) unless Rake::Task.task_defined?(:environment)
    Rails.application.load_tasks unless Rake::Task.task_defined?("mermaid_erd")
    @browser = Ferrum::Browser.new(
      timeout: 20,
      process_timeout: 30,
      # The dev container runs Chrome as root, which requires disabling the sandbox.
      # The examples find options by their English labels, and the viewer picks
      # its language from the browser's.
      browser_options: {"no-sandbox" => nil, "lang" => "en-US"}
    )
  end

  after(:all) { @browser&.quit }

  before do
    FileUtils.mkdir_p(File.dirname(output_path))
    allow(RailsMermaidErd::Builder).to receive(:model_data).and_return(schema)
    allow(RailsMermaidErd.configuration).to receive(:result_path).and_return(output_path.relative_path_from(Rails.root).to_s)
    Rake::Task["mermaid_erd"].reenable
    Rake::Task["mermaid_erd"].invoke
  end

  after { FileUtils.rm_f(output_path) }

  # The viewer encodes its state as base64 JSON in the URL hash.
  def open_viewer(state)
    @browser.goto("about:blank")
    @browser.goto("file://#{output_path}##{Base64.strict_encode64(JSON.generate(state))}")
    wait_until("the viewer to mount") { @browser.evaluate("!!document.getElementById('app')?.hasAttribute('data-v-app')") }
  end

  def wait_until(what)
    100.times do
      return if yield
      sleep 0.05
    end
    raise "timed out waiting for #{what}"
  end

  def drawn_text
    @browser.evaluate("[...document.querySelectorAll('#preview svg text, #preview svg foreignObject')].map((node) => node.textContent).join('\\n')")
  end

  def expect_drawn(text)
    wait_until("the diagram to draw #{text.inspect}") { drawn_text.include?(text) }
  end

  def table_comment_checkbox
    xpath = "//label[.//span[normalize-space()='Show Table Comment']]//input[@type='checkbox']"
    @browser.at_xpath(xpath)
  end

  def current_state
    JSON.parse(Base64.decode64(@browser.evaluate("location.hash.slice(1)")))
  end

  context "when opening a link that does not mention table comments" do
    it "keeps every heading to the model name and leaves Show Table Comment unchecked" do
      open_viewer(selectModels: %w[User Post Tag])
      expect_drawn("Tag")

      expect(drawn_text).not_to include("ユーザー")
      expect(table_comment_checkbox.property("checked")).to be(false)
    end
  end

  context "when opening a link saved with Show Table Comment turned on" do
    it "puts the table comment after the model name, and only for models that have one" do
      open_viewer(selectModels: %w[User Post Tag], isShowTableComment: true)

      expect_drawn("User / ユーザー")
      expect(drawn_text).to match(/^Post$/)
      expect(table_comment_checkbox.property("checked")).to be(true)
    end

    it "shows a comment holding a quote and a line break on one line, quote included" do
      open_viewer(selectModels: %w[User Post Tag], isShowTableComment: true)

      expect_drawn(%(Tag / tag "kind" second line))
    end

    it "keeps drawing the relation between the models" do
      open_viewer(selectModels: %w[User Post], isShowTableComment: true, isShowRelationComment: true)

      expect_drawn("User / ユーザー")
      expect_drawn("User has_many posts")
    end
  end

  context "when ticking Show Table Comment" do
    it "adds the table comment to the heading and saves the choice in the URL" do
      open_viewer(selectModels: %w[User Post])
      expect_drawn("User")

      table_comment_checkbox.click

      expect_drawn("User / ユーザー")
      wait_until("the choice to reach the URL") { current_state["isShowTableComment"] == true }
    end
  end
end
