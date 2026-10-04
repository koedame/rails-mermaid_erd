require "spec_helper"
require "rake"
require "ferrum"
require "json"
require "base64"

# What the viewer shows on a first visit is only observable in a real browser:
# the starting selection and column choice are applied while Vue mounts, and the
# diagram is drawn by Mermaid afterwards. These examples generate the viewer
# with a given `viewer_defaults`, open it, and read the result out of the page.
describe "generated viewer default view" do
  let(:output_path) { Rails.root.join("tmp/mermaid_erd_defaults_spec.html") }

  let(:schema) do
    {
      Models: [
        {
          TableName: "users", TableComment: nil, ModelName: "User", IsModelExist: true,
          Columns: [
            {name: "id", type: :integer, key: "PK", comment: nil},
            {name: "team_id", type: :integer, key: "FK", comment: nil},
            {name: "nickname", type: :string, key: "", comment: nil}
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
      Relations: []
    }
  end

  let(:viewer_defaults) { {models: [], columns: "all"} }
  let(:all_column_names) { %w[id team_id nickname user_id title] }

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
    allow(RailsMermaidErd.configuration).to receive(:viewer_defaults).and_return(viewer_defaults)
    Rake::Task["mermaid_erd"].reenable
    Rake::Task["mermaid_erd"].invoke
  end

  after { FileUtils.rm_f(output_path) }

  # `state` is the viewer's saved state as a link carries it (base64 JSON in the
  # URL hash); without one the viewer opens the way a first visit does.
  def open_viewer(state = nil)
    @browser.goto("about:blank")
    @browser.goto("file://#{output_path}#{"##{Base64.strict_encode64(JSON.generate(state))}" if state}")
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

  def drawn_words(candidates)
    text = drawn_text
    candidates.select { |word| text.match?(/(?<!\w)#{word}(?!\w)/) }
  end

  # The models and columns of the fixture that appear in the rendered diagram.
  def expect_drawn(models:, columns:)
    wait_until("the diagram to draw #{models.inspect} with #{columns.inspect}") do
      drawn_words(%w[User Post]) == models && drawn_words(all_column_names) == columns
    end
  end

  def column_choice(value)
    "input[type=radio][name=columns][value=#{value}]"
  end

  def checked?(selector)
    @browser.evaluate("document.querySelector(#{selector.to_json}).checked")
  end

  def current_state
    JSON.parse(Base64.decode64(@browser.evaluate("location.hash.slice(1)")))
  end

  def press_reset
    @browser.at_xpath("//button[.//span[normalize-space()='Reset']]").click
  end

  context "when viewer_defaults is not configured" do
    it "opens with nothing selected and asks for a model" do
      open_viewer

      wait_until("the empty state to show") { @browser.evaluate("document.body.innerText").include?("No models selected") }
      expect(current_state["selectModels"]).to eq([])
      expect(checked?(column_choice("all"))).to be(true)
    end
  end

  context "when viewer_defaults selects User and Keys Only" do
    let(:viewer_defaults) { {models: %w[User], columns: "keys"} }

    it "opens on a first visit with User drawn with only its key columns" do
      open_viewer

      expect_drawn(models: %w[User], columns: %w[id team_id])
      expect(checked?(column_choice("keys"))).to be(true)
      expect(@browser.evaluate("document.body.innerText")).not_to include("No models selected")
      expect(current_state).to include("selectModels" => %w[User], "columns" => "keys")
    end

    it "opens a link that carries its own choices as the link says" do
      open_viewer(selectModels: %w[Post], columns: "all")

      expect_drawn(models: %w[Post], columns: %w[id user_id title])
      expect(checked?(column_choice("all"))).to be(true)
    end

    it "opens a link that names no models and no columns with the defaults" do
      open_viewer(isPreviewRelations: false)

      expect_drawn(models: %w[User], columns: %w[id team_id])
      expect(checked?(column_choice("keys"))).to be(true)
    end

    it "keeps an empty selection saved in a link empty" do
      open_viewer(selectModels: [], columns: "keys")

      wait_until("the empty state to show") { @browser.evaluate("document.body.innerText").include?("No models selected") }
    end

    it "opens a link saved with the earlier Hide Columns checkbox turned off with every column" do
      open_viewer(selectModels: %w[User], isHideColumns: false)

      expect_drawn(models: %w[User], columns: %w[id team_id nickname])
      expect(checked?(column_choice("all"))).to be(true)
    end

    it "returns to the defaults after pressing Reset" do
      open_viewer(selectModels: %w[Post], columns: "all")
      expect_drawn(models: %w[Post], columns: %w[id user_id title])

      press_reset

      expect_drawn(models: %w[User], columns: %w[id team_id])
      expect(checked?(column_choice("keys"))).to be(true)
      expect(current_state).to include("selectModels" => %w[User], "columns" => "keys")
    end
  end
end
