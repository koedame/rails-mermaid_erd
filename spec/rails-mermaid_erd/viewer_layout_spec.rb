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

  def scroll_sidebar_to(position)
    @browser.evaluate(<<~JS)
      (() => {
        const aside = document.querySelector('aside')
        aside.scrollTop = #{(position == :bottom) ? "aside.scrollHeight" : Integer(position)}
        aside.dispatchEvent(new Event('scroll'))
      })()
    JS
    wait_for_stable_layout
  end

  def filter_models(text)
    @browser.evaluate(<<~JS)
      (() => {
        const input = document.querySelector('aside input[type="search"]')
        input.value = #{text.to_json}
        input.dispatchEvent(new Event('input'))
      })()
    JS
    wait_for_stable_layout
  end

  # Where the sidebar, its sticky model header, and each rendered model row
  # currently sit on screen.
  def sidebar_state
    measure(<<~JS)
      const aside = document.querySelector('aside')
      const rect = aside.getBoundingClientRect()
      const filterInput = document.querySelector('aside input[type="search"]')
      const filter = filterInput.getBoundingClientRect()
      const list = document.querySelector('.model-list')
      const labels = [...list.querySelectorAll('label')]
      const headerBottom = list.previousElementSibling.getBoundingClientRect().bottom
      const rows = labels.map((label) => {
        const r = label.getBoundingClientRect()
        return { name: label.textContent.trim(), top: r.top, bottom: r.bottom }
      })
      return {
        top: rect.top,
        bottom: rect.top + aside.clientHeight,
        filterTop: filter.top,
        filterBottom: filter.bottom,
        // What a click in the middle of the filter would hit: rows scrolling
        // under the header must not be painted over it.
        filterOnTop: document.elementFromPoint(filter.left + filter.width / 2, filter.top + filter.height / 2) === filterInput,
        rowPeeksAboveHeader: !!document.elementFromPoint(filter.left + filter.width / 2, rect.top + 1).closest('label'),
        headerBottom,
        listHasOwnScrollbox: list.scrollHeight > list.clientHeight,
        rows,
        visibleRows: rows.filter((row) => row.top >= headerBottom && row.bottom <= rect.top + aside.clientHeight).map((row) => row.name)
      }
    JS
  end

  def expect_model_header_pinned(state)
    expect(state["filterTop"]).to be >= state["top"]
    expect(state["filterBottom"]).to be <= state["headerBottom"]
    expect(state["filterOnTop"]).to be(true)
    expect(state["rowPeeksAboveHeader"]).to be(false)
  end

  # Every row slot between the sticky header and the bottom of the sidebar
  # holds a model: no blank band left by rendering too few virtual rows.
  def expect_rows_to_fill_sidebar(state)
    slots = ((state["bottom"] - state["headerBottom"]) / 24).floor
    expect(state["visibleRows"].size).to be >= slots - 1
    expect(state["rows"].last["bottom"]).to be >= state["bottom"]
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

    it "scrolls the model list with the sidebar while the model filter stays pinned above the rows" do
      scroll_sidebar_to(3000)
      state = sidebar_state

      expect(state["listHasOwnScrollbox"]).to be(false)
      expect_model_header_pinned(state)
      expect_rows_to_fill_sidebar(state)
    end

    it "shows the last model below the pinned filter after scrolling the sidebar to the bottom" do
      scroll_sidebar_to(:bottom)
      state = sidebar_state

      expect(state["visibleRows"].last).to eq("Model299")
      expect_model_header_pinned(state)
    end

    it "keeps each checkbox reached by Shift+Tab visible instead of hidden under the model header" do
      scroll_sidebar_to(3000)
      first_visible = sidebar_state["visibleRows"].first
      @browser.evaluate(<<~JS)
        [...document.querySelectorAll('.model-list label')]
          .find((label) => label.textContent.trim() === #{first_visible.to_json})
          .querySelector('input').focus()
      JS

      hidden = 5.times.map do
        @browser.keyboard.type([:Shift, :Tab])
        wait_for_stable_layout
        @browser.evaluate(<<~JS)
          (() => {
            const focused = document.activeElement
            const rect = focused.getBoundingClientRect()
            return document.elementFromPoint(rect.left + rect.width / 2, rect.top + rect.height / 2) !== focused
          })()
        JS
      end

      expect(hidden).to all(be(false))
    end

    it "keeps the sidebar where it was when clearing a filter that had shortened the list" do
      scroll_sidebar_to(1500)
      # "Model00" leaves ten rows, so the browser pulls the scroll position back.
      filter_models("Model00")
      scroll_top = -> { @browser.evaluate("document.querySelector('aside').scrollTop") }
      before_clearing = scroll_top.call
      filter_models("")

      expect(scroll_top.call).to eq(before_clearing)
    end

    it "shows the first matching models under the filter when filtering after scrolling down" do
      scroll_sidebar_to(:bottom)
      # "Model1" matches Model100-Model199: still enough rows to be virtualised.
      filter_models("Model1")
      state = sidebar_state

      expect(state["visibleRows"].first(3)).to eq(%w[Model100 Model101 Model102])
      expect_model_header_pinned(state)
    end
  end

  context "when the schema has hundreds of models in a tall window" do
    it "fills the sidebar with model rows before it is scrolled" do
      open_viewer(model_count: 300, width: 1280, height: 1600)

      expect_rows_to_fill_sidebar(sidebar_state)
    end

    it "fills the sidebar with model rows when the window grows taller after scrolling" do
      open_viewer(model_count: 300, width: 1280, height: 800)
      scroll_sidebar_to(3000)
      @browser.resize(width: 1280, height: 1600)
      wait_for_stable_layout

      expect_rows_to_fill_sidebar(sidebar_state)
    end
  end

  context "when the schema has hundreds of models in a short window" do
    before { open_viewer(model_count: 300, width: 1280, height: 400) }

    it "keeps the page within the window and still reaches the last model by scrolling the sidebar" do
      page = measure("return { innerHeight: window.innerHeight, scrollHeight: document.scrollingElement.scrollHeight }")
      scroll_sidebar_to(:bottom)
      state = sidebar_state

      expect(page["scrollHeight"]).to be <= page["innerHeight"]
      expect(state["visibleRows"].last).to eq("Model299")
      expect_model_header_pinned(state)
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

    it "draws the sidebar divider on the diagram side after switching to a right-to-left language" do
      @browser.evaluate(<<~JS)
        (() => {
          const select = document.querySelector('header select')
          select.value = 'ar'
          select.dispatchEvent(new Event('change'))
        })()
      JS
      wait_for_stable_layout

      divider = measure(<<~JS)
        const aside = document.querySelector('aside')
        const style = getComputedStyle(aside)
        return {
          sidebarOnRight: aside.getBoundingClientRect().left > document.querySelector('main').getBoundingClientRect().left,
          left: style.borderLeftWidth,
          right: style.borderRightWidth
        }
      JS

      expect(divider).to eq("sidebarOnRight" => true, "left" => "1px", "right" => "0px")
    end
  end
end
