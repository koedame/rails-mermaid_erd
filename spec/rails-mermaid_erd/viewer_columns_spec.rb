require "spec_helper"
require "rake"
require "ferrum"
require "json"
require "base64"

# Which columns the diagram draws is only observable in a real browser: the
# option is applied while Vue builds the Mermaid source, and Mermaid renders it
# asynchronously. These examples choose the option the way a user does and read
# the column names out of the rendered SVG.
describe "generated viewer column display" do
  let(:output_path) { Rails.root.join("tmp/mermaid_erd_columns_spec.html") }

  let(:schema) do
    {
      Models: [
        {
          TableName: "users", TableComment: nil, ModelName: "User", IsModelExist: true,
          Columns: [
            {name: "id", type: :integer, key: "PK", comment: nil},
            {name: "team_id", type: :integer, key: "FK", comment: nil},
            {name: "nickname", type: :string, key: "", comment: "shown on profile"}
          ]
        },
        {
          TableName: "posts", TableComment: nil, ModelName: "Post", IsModelExist: true,
          Columns: [
            {name: "id", type: :integer, key: "PK", comment: nil},
            {name: "user_id", type: :integer, key: "FK", comment: nil},
            {name: "title", type: :string, key: "", comment: nil}
          ]
        }
      ],
      Relations: [
        {LeftModelName: "User", LeftValue: "||", Line: "--", RightValue: "o{", RightModelName: "Post", Comment: "User has_many posts"}
      ]
    }
  end

  let(:all_column_names) { %w[id team_id nickname user_id title] }
  let(:key_column_names) { %w[id team_id user_id] }

  before(:all) do
    Rake::Task.define_task(:environment) unless Rake::Task.task_defined?(:environment)
    Rails.application.load_tasks unless Rake::Task.task_defined?("mermaid_erd")
    @browser = Ferrum::Browser.new(
      timeout: 20,
      process_timeout: 30,
      # The dev container runs Chrome as root, which requires disabling the sandbox.
      browser_options: {"no-sandbox" => nil}
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

  # Column names of the fixture that appear in the rendered diagram, once it
  # has been drawn with the given names.
  def expect_drawn_columns(names)
    wait_until("the diagram to draw #{names.inspect}") do
      text = drawn_text
      text.include?("User") && all_column_names.select { |name| text.match?(/(?<!\w)#{name}(?!\w)/) } == names
    end
  end

  def column_choice(value)
    "input[type=radio][name=columns][value=#{value}]"
  end

  def choose_columns(value)
    @browser.at_css(column_choice(value)).click
  end

  def checked?(selector)
    @browser.evaluate("document.querySelector(#{selector.to_json}).checked")
  end

  def option_disabled?(label)
    xpath = "//label[.//span[normalize-space()=#{label.to_json}]]//input[@type='checkbox']"
    @browser.evaluate("document.evaluate(#{xpath.to_json}, document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue.disabled")
  end

  def current_state
    JSON.parse(Base64.decode64(@browser.evaluate("location.hash.slice(1)")))
  end

  context "when opening a link that does not mention which columns to show" do
    it "draws every column and selects All" do
      open_viewer(selectModels: %w[User Post])

      expect_drawn_columns(all_column_names)
      expect(checked?(column_choice("all"))).to be(true)
    end
  end

  context "when choosing Keys Only" do
    it "draws only the primary and foreign key columns" do
      open_viewer(selectModels: %w[User Post])
      choose_columns("keys")

      expect_drawn_columns(key_column_names)
    end

    it "keeps Show Key and Show Column Comment available" do
      open_viewer(selectModels: %w[User Post])
      choose_columns("keys")

      expect(option_disabled?("Show Key")).to be(false)
      expect(option_disabled?("Show Column Comment")).to be(false)
    end

    it "opens the copied link with Keys Only still selected" do
      open_viewer(selectModels: %w[User Post])
      choose_columns("keys")
      wait_until("the choice to reach the URL") { current_state["columns"] == "keys" }

      open_viewer(current_state)

      expect_drawn_columns(key_column_names)
      expect(checked?(column_choice("keys"))).to be(true)
    end

    it "draws every column again after pressing Reset and selecting the models" do
      open_viewer(selectModels: %w[User Post])
      choose_columns("keys")
      @browser.at_xpath("//button[.//span[normalize-space()='Reset']]").click
      wait_until("reset to clear the selection") { current_state["selectModels"] == [] }

      open_viewer(current_state.merge("selectModels" => %w[User Post]))

      expect_drawn_columns(all_column_names)
      expect(checked?(column_choice("all"))).to be(true)
    end
  end

  context "when choosing None" do
    it "draws no columns and disables Show Key and Show Column Comment" do
      open_viewer(selectModels: %w[User Post])
      choose_columns("none")

      expect_drawn_columns([])
      expect(option_disabled?("Show Key")).to be(true)
      expect(option_disabled?("Show Column Comment")).to be(true)
    end
  end

  context "when opening a link saved with the earlier Hide Columns checkbox turned on" do
    it "draws no columns and selects None" do
      open_viewer(selectModels: %w[User Post], isHideColumns: true)

      expect_drawn_columns([])
      expect(checked?(column_choice("none"))).to be(true)
    end
  end
end
