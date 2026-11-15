require "spec_helper"
require "rake"
require "ferrum"
require "json"

# Pan and zoom are only observable in a real browser: these examples send
# wheel and key input through Chrome's input pipeline and measure where the
# diagram layer ends up on screen.
describe "generated viewer navigation" do
  let(:output_path) { Rails.root.join("tmp/mermaid_erd_navigation_spec.html") }

  # Modifier bit masks of the DevTools protocol's Input domain.
  let(:ctrl) { 2 }
  let(:meta) { 4 }
  let(:shift) { 8 }

  before(:all) do
    Rake::Task.define_task(:environment) unless Rake::Task.task_defined?(:environment)
    Rails.application.load_tasks unless Rake::Task.task_defined?("mermaid_erd")
    @browser = HeadlessBrowser.launch(
      # The dev container runs Chrome as root, which requires disabling the sandbox.
      browser_options: {"no-sandbox" => nil}
    )
  end

  after(:all) { @browser&.quit }

  after { FileUtils.rm_f(output_path) }

  let(:model_count) { 1 }

  before do
    FileUtils.mkdir_p(File.dirname(output_path))
    models = Array.new(model_count) do |i|
      {TableName: format("table_%03d", i), TableComment: nil, ModelName: format("Model%03d", i), IsModelExist: true, Columns: [{name: "id", type: :integer, key: "PK", comment: nil}]}
    end
    schema = {Models: models, Relations: []}
    allow(RailsMermaidErd::Builder).to receive(:model_data).and_return(schema)
    allow(RailsMermaidErd.configuration).to receive(:result_path).and_return(output_path.relative_path_from(Rails.root).to_s)
    Rake::Task["mermaid_erd"].reenable
    Rake::Task["mermaid_erd"].invoke

    @browser.resize(width: 1280, height: 800)
    @browser.goto("file://#{output_path}")
    # The scroll choice is remembered per device: start each example without one.
    @browser.evaluate("window.localStorage.clear()")
    @browser.refresh
    wait_for_viewer
  end

  def wait_for_viewer
    50.times do
      ready = @browser.evaluate(<<~JS)
        (() => {
          const app = document.getElementById('app')
          const viewport = document.getElementById('preview')?.parentElement?.parentElement
          return !!(app && app.hasAttribute('data-v-app') && viewport && viewport.clientWidth > 0 && viewport.clientHeight > 0)
        })()
      JS
      return if ready
      sleep 0.1
    end
    raise "viewer did not mount"
  end

  # Where the diagram layer sits relative to the diagram area: its offset in
  # screen pixels and its scale.
  def view
    JSON.parse(@browser.evaluate(<<~JS))
      JSON.stringify((() => {
        const layer = document.getElementById('preview').parentElement
        const viewport = layer.parentElement
        const outer = viewport.getBoundingClientRect()
        const inner = layer.getBoundingClientRect()
        return { x: inner.left - outer.left, y: inner.top - outer.top, scale: inner.width / viewport.clientWidth }
      })())
    JS
  end

  def diagram_point(dx, dy)
    rect = JSON.parse(@browser.evaluate("JSON.stringify(document.getElementById('preview').parentElement.parentElement.getBoundingClientRect())"))
    [rect["left"] + dx, rect["top"] + dy]
  end

  def sidebar_point
    rect = JSON.parse(@browser.evaluate("JSON.stringify(document.querySelector('aside').getBoundingClientRect())"))
    [rect["left"] + rect["width"] / 2, rect["top"] + rect["height"] / 2]
  end

  def wheel(at:, delta_x: 0, delta_y: 0, modifiers: 0)
    x, y = at
    @browser.page.command("Input.dispatchMouseEvent", type: "mouseMoved", x: x, y: y)
    @browser.page.command("Input.dispatchMouseEvent", type: "mouseWheel", x: x, y: y, deltaX: delta_x, deltaY: delta_y, modifiers: modifiers)
    settle
  end

  def press(*keys)
    @browser.keyboard.type(*keys)
    settle
  end

  # Vue patches the transform on the next tick.
  def settle
    @browser.evaluate("new Promise((resolve) => requestAnimationFrame(() => requestAnimationFrame(resolve)))")
  end

  # The diagram-layer coordinate currently drawn under a point of the diagram area.
  def layer_point_under(view, x, y)
    [(x - view["x"]) / view["scale"], (y - view["y"]) / view["scale"]]
  end

  # Dispatches a wheel event with the values a given device reports. Chrome's
  # DevTools input always produces a mouse wheel's shape (wheelDeltaY of 120 per
  # notch), so the shapes of a trackpad, Safari and Firefox are built by hand.
  def device_wheel(at:, delta_y: 0, delta_x: 0, wheel_delta_y: nil, delta_mode: 0)
    x, y = at
    @browser.evaluate(<<~JS)
      (() => {
        const event = new WheelEvent('wheel', { bubbles: true, cancelable: true, clientX: #{x}, clientY: #{y}, deltaX: #{delta_x}, deltaY: #{delta_y}, deltaMode: #{delta_mode} })
        #{"Object.defineProperty(event, 'wheelDeltaY', { value: #{wheel_delta_y} })" unless wheel_delta_y.nil?}
        document.elementFromPoint(#{x}, #{y}).dispatchEvent(event)
        return event.defaultPrevented
      })()
    JS
  end

  def choose_two_finger_scroll(label)
    @browser.evaluate(<<~JS)
      [...document.querySelectorAll('button[aria-pressed]')].find((b) => b.textContent.trim() === #{label.to_json}).click()
    JS
    settle
  end

  context "when scrolling a mouse wheel over the diagram" do
    it "zooms in around the pointer by one zoom-in button step per notch" do
      before_zoom = view
      wheel(at: diagram_point(300, 200), delta_y: -100)
      after_zoom = view

      expect(after_zoom["scale"]).to be_within(0.001).of(1.2)
      layer_point_under(after_zoom, 300, 200).zip(layer_point_under(before_zoom, 300, 200)).each do |after, before|
        expect(after).to be_within(0.01).of(before)
      end
    end

    it "zooms out by the same step when scrolled the other way, without moving the diagram" do
      wheel(at: diagram_point(300, 200), delta_y: 100)

      expect(view["scale"]).to be_within(0.001).of(1 / 1.2)
    end

    it "zooms the same for one notch whatever values the device reports" do
      at = diagram_point(300, 200)
      notches = {
        "Chrome on a Mac" => {delta_y: -4.000244140625, wheel_delta_y: 120},
        "Safari on a Mac" => {delta_y: -4.000244140625, wheel_delta_y: 12},
        "Chrome on Windows" => {delta_y: -100, wheel_delta_y: 120},
        "Firefox" => {delta_y: -3, delta_mode: 1}
      }

      notches.each do |device, values|
        @browser.evaluate("document.querySelector('[aria-label=\"Reset View\"]').click()")
        device_wheel(at: at, **values)
        settle
        expect(view["scale"]).to be_within(0.001).of(1.2), "one notch on #{device} zoomed to #{view["scale"]}"
      end
    end

    it "zooms around the pointer rather than moving the diagram when Shift is held" do
      wheel(at: diagram_point(300, 200), delta_y: 100, modifiers: shift)

      expect(view["scale"]).to be < 1
    end
  end

  context "when swiping two fingers over the diagram" do
    # A trackpad reports wheelDeltaY as -3 times the delta, a mouse wheel as a multiple of 120.
    def swipe(delta_x: 40, delta_y: 100)
      device_wheel(at: diagram_point(300, 200), delta_x: delta_x, delta_y: delta_y, wheel_delta_y: -3 * delta_y)
      settle
    end

    it "zooms by default, so that a mouse reporting itself as a trackpad can still zoom" do
      swipe(delta_x: 0, delta_y: -100)

      expect(view["scale"]).to be > 1
    end

    it "moves the diagram by the swiped distance without zooming once movement is chosen" do
      choose_two_finger_scroll("Movement")
      swipe

      expect(view).to eq("x" => -40, "y" => -100, "scale" => 1)
    end

    it "still zooms with a mouse wheel notch once movement is chosen" do
      choose_two_finger_scroll("Movement")
      wheel(at: diagram_point(300, 200), delta_y: -100)

      expect(view["scale"]).to be_within(0.001).of(1.2)
    end

    it "remembers the choice when the viewer is opened again" do
      choose_two_finger_scroll("Movement")
      @browser.refresh
      wait_for_viewer
      swipe

      expect(view).to eq("x" => -40, "y" => -100, "scale" => 1)
    end

    it "lists two-finger scrolling under zoom or movement according to the choice" do
      legend = -> { @browser.evaluate("document.querySelector('button[aria-pressed]').closest('.flex-col').textContent.replace(/\\s+/g, ' ')") }

      expect(legend.call).to match(/Movement:Arrow Keys.*Zoom:Scroll/)
      choose_two_finger_scroll("Movement")
      expect(legend.call).to match(/Movement:Two-finger Scroll.*Zoom:Mouse Wheel/)
    end
  end

  context "when scrolling over the diagram with Ctrl or Command held" do
    it "zooms in around the pointer so the point under it stays put" do
      before_zoom = view
      wheel(at: diagram_point(300, 200), delta_y: -10, modifiers: ctrl)
      after_zoom = view

      expect(after_zoom["scale"]).to be > 1
      layer_point_under(after_zoom, 300, 200).zip(layer_point_under(before_zoom, 300, 200)).each do |after, before|
        expect(after).to be_within(0.01).of(before)
      end
    end

    it "zooms out with Command held as well" do
      wheel(at: diagram_point(300, 200), delta_y: 10, modifiers: meta)

      expect(view["scale"]).to be < 1
    end

    it "scales the diagram by as much as a trackpad pinch spreads the fingers" do
      # Chrome reports a pinch that doubles the finger spread as Ctrl + wheel
      # events whose deltaY adds up to -100 * ln(2).
      7.times { wheel(at: diagram_point(300, 200), delta_y: -100 * Math.log(2) / 7, modifiers: ctrl) }

      expect(view["scale"]).to be_within(0.01).of(2)
    end

    it "zooms one mouse wheel notch by the same step as the zoom-in button" do
      wheel(at: diagram_point(300, 200), delta_y: -100, modifiers: ctrl)

      expect(view["scale"]).to be_within(0.001).of(1.2)
    end
  end

  context "when scrolling outside the diagram" do
    it "leaves the diagram where it was" do
      wheel(at: sidebar_point, delta_y: 100)
      wheel(at: sidebar_point, delta_y: -10, modifiers: ctrl)

      expect(view).to eq("x" => 0, "y" => 0, "scale" => 1)
    end
  end

  context "when pinching on a Safari trackpad" do
    # Safari reports trackpad pinches as gesture events carrying the scale
    # since the gesture started, not as Ctrl + wheel events. Chrome has no
    # gesture events, so the events are built by hand here.
    def gesture(type, scale:, at:)
      x, y = at
      @browser.evaluate(<<~JS)
        (() => {
          const event = new Event(#{type.to_json}, { bubbles: true, cancelable: true })
          Object.defineProperties(event, { scale: { value: #{scale} }, clientX: { value: #{x} }, clientY: { value: #{y} } })
          document.elementFromPoint(#{x}, #{y}).dispatchEvent(event)
          return event.defaultPrevented
        })()
      JS
    end

    it "scales the diagram with the fingers instead of zooming the page" do
      at = diagram_point(300, 200)
      prevented = gesture("gesturestart", scale: 1, at: at)
      gesture("gesturechange", scale: 1.5, at: at)
      gesture("gesturechange", scale: 2, at: at)
      gesture("gestureend", scale: 2, at: at)
      settle

      expect(prevented).to be(true)
      expect(view["scale"]).to be_within(0.001).of(2)
    end
  end

  context "when pinching with two fingers on a touch screen that also sends gesture events" do
    # iOS Safari reports one pinch both as touch events and as gesture events.
    def touch(type, points)
      @browser.page.command("Input.dispatchTouchEvent", type: type, touchPoints: points.map { |x, y| {x: x, y: y} })
    end

    def gesture(type, scale:, at:)
      x, y = at
      @browser.evaluate(<<~JS)
        (() => {
          const event = new Event(#{type.to_json}, { bubbles: true, cancelable: true })
          Object.defineProperties(event, { scale: { value: #{scale} }, clientX: { value: #{x} }, clientY: { value: #{y} } })
          document.elementFromPoint(#{x}, #{y}).dispatchEvent(event)
        })()
      JS
    end

    it "scales the diagram once with the fingers" do
      @browser.page.command("Emulation.setTouchEmulationEnabled", enabled: true, maxTouchPoints: 2)
      cx, cy = diagram_point(300, 200)
      touch("touchStart", [[cx - 50, cy], [cx + 50, cy]])
      gesture("gesturestart", scale: 1, at: [cx, cy])
      touch("touchMove", [[cx - 100, cy], [cx + 100, cy]])
      gesture("gesturechange", scale: 2, at: [cx, cy])
      touch("touchEnd", [])
      gesture("gestureend", scale: 2, at: [cx, cy])
      settle

      expect(view["scale"]).to be_within(0.001).of(2)
    ensure
      @browser.page.command("Emulation.setTouchEmulationEnabled", enabled: false)
    end
  end

  context "when the model list is long enough to scroll" do
    let(:model_count) { 300 }

    def click(x, y)
      @browser.mouse.click(x: x, y: y)
      settle
    end

    # Keyboard scrolling is animated, so the scroll position is polled until it moves.
    def eventually(timeout: 5)
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
      begin
        yield
      rescue RSpec::Expectations::ExpectationNotMetError
        raise if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
        sleep 0.1
        retry
      end
    end

    it "scrolls the model list with the arrow keys after a model is clicked, leaving the diagram where it was" do
      checkbox = JSON.parse(@browser.evaluate("JSON.stringify(document.querySelector('.model-list input').getBoundingClientRect())"))
      click(checkbox["left"] + checkbox["width"] / 2, checkbox["top"] + checkbox["height"] / 2)
      before_keys = view
      press(:Down)
      press(:Down)

      eventually { expect(@browser.evaluate("document.querySelector('aside').scrollTop")).to be > 0 }
      expect(view).to eq(before_keys)
    end

    it "moves the diagram with the arrow keys again once the diagram is clicked" do
      checkbox = JSON.parse(@browser.evaluate("JSON.stringify(document.querySelector('.model-list input').getBoundingClientRect())"))
      click(checkbox["left"] + checkbox["width"] / 2, checkbox["top"] + checkbox["height"] / 2)
      click(*diagram_point(600, 150))
      before_keys = view
      press(:Down)

      expect(view["y"]).to eq(before_keys["y"] + 60)
    end
  end

  context "when nothing that takes typing has focus" do
    it "moves the diagram with the arrow keys the same way as the on-screen arrow buttons" do
      press(:Up)
      press(:Left)
      by_keys = view
      press("0")
      @browser.evaluate("[...document.querySelectorAll('main button')].find((b) => b.textContent.trim() === '↑').click()")
      @browser.evaluate("[...document.querySelectorAll('main button')].find((b) => b.textContent.trim() === '←').click()")
      settle

      expect(by_keys).to eq(view)
      expect(by_keys.values_at("x", "y")).to all(be < 0)
    end

    it "zooms in with +, zooms out with - and restores the initial view with 0" do
      press("+")
      zoomed_in = view["scale"]
      press("-")
      press("-")
      zoomed_out = view["scale"]
      press(:Down)
      press("0")

      expect(zoomed_in).to be_within(0.001).of(1.2)
      expect(zoomed_out).to be_within(0.001).of(1 / 1.2)
      expect(view).to eq("x" => 0, "y" => 0, "scale" => 1)
    end

    it "zooms in with = so + works without Shift on keyboards that put it on the same key" do
      press("=")

      expect(view["scale"]).to be_within(0.001).of(1.2)
    end

    it "leaves Ctrl + - to the browser's own page zoom" do
      press([:Control, "-"])

      expect(view).to eq("x" => 0, "y" => 0, "scale" => 1)
    end
  end

  context "when typing into the model filter" do
    it "moves the text cursor instead of the diagram" do
      @browser.evaluate("document.querySelector('aside input[type=\"search\"]').focus()")
      press("a-0+")
      press(:Left)
      press(:Up)

      expect(@browser.evaluate("document.querySelector('aside input[type=\"search\"]').value")).to eq("a-0+")
      expect(view).to eq("x" => 0, "y" => 0, "scale" => 1)
    end
  end
end
