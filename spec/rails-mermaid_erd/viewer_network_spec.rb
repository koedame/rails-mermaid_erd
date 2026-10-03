require "spec_helper"
require "rake"
require "ferrum"
require "json"
require "base64"

# The README promises that the generated file makes no network requests while
# it is viewed, so it can be opened offline and shared without telling anyone
# outside. A string search for CDN hostnames (see rake_task_spec.rb) cannot
# prove that: the bundled Mermaid calls fetch() from code that only runs when a
# diagram is drawn. These examples open the file in headless Chrome, draw a
# diagram, and look at every request the page actually made.
describe "generated viewer network traffic" do
  let(:output_path) { Rails.root.join("tmp/mermaid_erd_network_spec.html") }

  let(:schema) do
    {
      Models: [
        {
          TableName: "users", TableComment: "Registered users", ModelName: "User", IsModelExist: true,
          Columns: [
            {name: "id", type: :integer, key: "PK", comment: nil},
            {name: "name", type: :string, key: "", comment: "Display name"}
          ]
        },
        {
          TableName: "posts", TableComment: nil, ModelName: "Post", IsModelExist: true,
          Columns: [
            {name: "id", type: :integer, key: "PK", comment: nil},
            {name: "user_id", type: :integer, key: "FK", comment: nil}
          ]
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
      # The examples find controls by their English labels, and the viewer picks
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
    # Tall enough that the model list is not hidden behind the options.
    @browser.resize(width: 1280, height: 1200)
    @browser.goto("about:blank")
    @browser.network.clear(:traffic)
  end

  after { FileUtils.rm_f(output_path) }

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

  def open_viewer(state = nil)
    hash = state ? "##{Base64.strict_encode64(JSON.generate(state))}" : ""
    @browser.goto("file://#{output_path}#{hash}")
    wait_until("the viewer to mount") { @browser.evaluate("!!document.getElementById('app')?.hasAttribute('data-v-app')") }
  end

  def requested_urls
    @browser.network.traffic.map { |exchange| exchange.request.url }
  end

  def requests_outside_the_file
    requested_urls.reject { |url| url.start_with?("file:", "data:") }
  end

  context "when opening the viewer, picking a model and drawing it" do
    it "requests nothing except the file itself and data: URLs" do
      open_viewer
      @browser.at_css(".model-list input[type=checkbox][value=User]").click
      wait_until("the diagram to draw User") { drawn_text.include?("User") }

      expect(requested_urls).to include(start_with("file:"))
      expect(requests_outside_the_file).to eq([])
    end
  end

  context "when opening a link that draws two related models with every detail on" do
    it "requests nothing except the file itself and data: URLs" do
      open_viewer(
        selectModels: %w[User Post], isShowKey: true, isShowComment: true,
        isShowTableComment: true, isShowRelationComment: true
      )
      wait_until("the relation to draw") { drawn_text.include?("User has_many posts") }

      expect(requests_outside_the_file).to eq([])
    end
  end

  context "when opening a link saved in snapshot mode" do
    it "requests nothing except the file itself and data: URLs" do
      open_viewer(selectModels: %w[User Post], isSnapshotMode: true)
      wait_until("the snapshot to be taken") { @browser.evaluate("(document.querySelector('img[alt=\"ERD snapshot\"]')?.src || '').startsWith('data:')") }

      expect(requests_outside_the_file).to eq([])
    end
  end
end
