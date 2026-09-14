require "spec_helper"
require "rake"
require "ferrum"
require "json"

# Layout is only observable in a real browser: the viewer's Tailwind classes
# are compiled at runtime and the page height depends on the rendered model
# list. These examples render the generated HTML in headless Chrome and
# measure it, so they fail on the way the page actually looks rather than on
# the class names it happens to use.
describe "generated viewer layout" do
  let(:output_path) { Rails.root.join("tmp/mermaid_erd_layout_spec.html") }

  before(:all) do
    Rake::Task.define_task(:environment) unless Rake::Task.task_defined?(:environment)
    Rails.application.load_tasks unless Rake::Task.task_defined?("mermaid_erd")
    @browser = Ferrum::Browser.new(
      timeout: 20,
      process_timeout: 30,
      # Ferrum hides scrollbars by default, which would make an always-on
      # scrollbar invisible to the examples below; drop that single default.
      ignore_default_browser_options: true,
      browser_options: Ferrum::Browser::Options::Chrome::DEFAULT_OPTIONS
        .except("hide-scrollbars")
        # The dev container runs Chrome as root, which requires disabling the sandbox.
        .merge("no-sandbox" => nil)
    )
  end

  after(:all) { @browser&.quit }

  after { FileUtils.rm_f(output_path) }

  def schema_with(model_count)
    models = Array.new(model_count) do |i|
      {
        TableName: format("table_%03d", i),
        TableComment: nil,
        ModelName: format("Model%03d", i),
        IsModelExist: true,
        Columns: [{name: "id", type: :integer, key: "PK", comment: nil}]
      }
    end
    {Models: models, Relations: []}
  end

  def open_viewer(model_count:, width:, height:)
    FileUtils.mkdir_p(File.dirname(output_path))
    allow(RailsMermaidErd::Builder).to receive(:model_data).and_return(schema_with(model_count))
    allow(RailsMermaidErd.configuration).to receive(:result_path).and_return(output_path.relative_path_from(Rails.root).to_s)
    Rake::Task["mermaid_erd"].reenable
    Rake::Task["mermaid_erd"].invoke

    @browser.resize(width: width, height: height)
    @browser.goto("file://#{output_path}")
    wait_for_stable_layout
  end

  # Vue mounts and the Tailwind runtime generates styles asynchronously, and
  # each can trigger the other again, so wait until two samples in a row agree.
  def wait_for_stable_layout
    previous = nil
    50.times do
      current = @browser.evaluate(<<~JS)
        (() => {
          const app = document.getElementById('app')
          const header = document.querySelector('header')
          if (!app || !app.hasAttribute('data-v-app')) return null
          if (getComputedStyle(header).backgroundColor === 'rgba(0, 0, 0, 0)') return null
          return JSON.stringify([...document.querySelectorAll('header, aside, main, footer, .model-list')]
            .map((el) => [el.getBoundingClientRect().height, el.scrollHeight, el.querySelectorAll('label').length]))
        })()
      JS
      return if current && current == previous
      previous = current
      sleep 0.1
    end
    raise "viewer layout did not settle"
  end

  def measure(script)
    JSON.parse(@browser.evaluate("JSON.stringify((() => { #{script} })())"))
  end

  def scroll_model_list_to_bottom
    @browser.evaluate(<<~JS)
      (() => {
        const list = document.querySelector('.model-list')
        list.scrollTop = list.scrollHeight
        list.dispatchEvent(new Event('scroll'))
      })()
    JS
    wait_for_stable_layout
  end

  context "when the schema has hundreds of models in a regular window" do
    before { open_viewer(model_count: 300, width: 1280, height: 800) }

    it "keeps the page within the window, so the footer and every diagram control stay visible" do
      page = measure(<<~JS)
        return {
          innerHeight: window.innerHeight,
          scrollHeight: document.scrollingElement.scrollHeight,
          footerBottom: document.querySelector('footer').getBoundingClientRect().bottom,
          lowestMainButton: Math.max(...[...document.querySelectorAll('main button')].map((b) => b.getBoundingClientRect().bottom))
        }
      JS

      expect(page["scrollHeight"]).to be <= page["innerHeight"]
      expect(page["footerBottom"]).to be <= page["innerHeight"]
      expect(page["lowestMainButton"]).to be <= page["innerHeight"]
    end

    it "scrolls only the model list, leaving the actions, options, and filter in place" do
      sidebar = measure(<<~JS)
        const aside = document.querySelector('aside')
        const list = document.querySelector('.model-list')
        return {
          asideScrollHeight: aside.scrollHeight, asideClientHeight: aside.clientHeight,
          listScrollHeight: list.scrollHeight, listClientHeight: list.clientHeight
        }
      JS

      expect(sidebar["asideScrollHeight"]).to be <= sidebar["asideClientHeight"]
      expect(sidebar["listScrollHeight"]).to be > sidebar["listClientHeight"]
    end

    it "shows the last model inside the list after scrolling the list to the bottom" do
      scroll_model_list_to_bottom

      last = measure(<<~JS)
        const list = document.querySelector('.model-list').getBoundingClientRect()
        const label = [...document.querySelectorAll('.model-list label')].find((l) => l.textContent.includes('Model299'))
        if (!label) return null
        const rect = label.getBoundingClientRect()
        return { visible: rect.top >= list.top && rect.bottom <= list.bottom }
      JS

      expect(last).to eq("visible" => true)
    end
  end

  context "when the schema has hundreds of models in a tall window" do
    before { open_viewer(model_count: 300, width: 1280, height: 1600) }

    it "fills the visible part of the model list with rows before it is scrolled" do
      list = measure(<<~JS)
        const list = document.querySelector('.model-list')
        const labels = [...list.querySelectorAll('label')]
        return {
          listBottom: list.getBoundingClientRect().bottom,
          lastRowBottom: labels[labels.length - 1].getBoundingClientRect().bottom
        }
      JS

      expect(list["lastRowBottom"]).to be >= list["listBottom"]
    end
  end

  context "when the schema has hundreds of models in a short window" do
    before { open_viewer(model_count: 300, width: 1280, height: 600) }

    it "keeps at least five rows of the model list visible and still fits the page in the window" do
      page = measure(<<~JS)
        return {
          innerHeight: window.innerHeight,
          scrollHeight: document.scrollingElement.scrollHeight,
          listClientHeight: document.querySelector('.model-list').clientHeight
        }
      JS

      expect(page["listClientHeight"]).to be >= 5 * 24
      expect(page["scrollHeight"]).to be <= page["innerHeight"]
    end
  end

  context "when the schema has few enough models to fit in the sidebar" do
    before { open_viewer(model_count: 3, width: 1280, height: 800) }

    it "shows no scrollbars in the sidebar" do
      gutters = measure(<<~JS)
        return [document.querySelector('aside'), document.querySelector('.model-list')].map((el) => {
          const style = getComputedStyle(el)
          const borders = parseFloat(style.borderLeftWidth) + parseFloat(style.borderRightWidth)
          const vertical = el.offsetWidth - el.clientWidth - borders
          const horizontal = el.offsetHeight - el.clientHeight - parseFloat(style.borderTopWidth) - parseFloat(style.borderBottomWidth)
          return [vertical, horizontal]
        })
      JS

      expect(gutters).to eq([[0, 0], [0, 0]])
    end

    it "stretches the diagram and the Mermaid code view down to the footer" do
      bottoms = measure(<<~JS)
        const footer = document.querySelector('footer').getBoundingClientRect()
        const diagram = document.getElementById('preview').closest('main > div:not(:first-child)')
        return {
          innerHeight: window.innerHeight,
          footerTop: footer.top,
          footerBottom: footer.bottom,
          diagramBottom: diagram.getBoundingClientRect().bottom
        }
      JS
      # The second tab button switches to the Mermaid code view.
      @browser.evaluate("document.querySelectorAll('main > div:first-child button')[1].click()")
      wait_for_stable_layout
      code_bottom = @browser.evaluate("document.querySelector('main textarea').getBoundingClientRect().bottom")

      expect(bottoms["footerBottom"]).to eq(bottoms["innerHeight"])
      expect(bottoms["diagramBottom"]).to eq(bottoms["footerTop"])
      expect(code_bottom).to eq(bottoms["footerTop"])
    end
  end
end
