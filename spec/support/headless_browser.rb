require "ferrum"

# Starts the headless Chrome the viewer specs drive. Every viewer spec file
# launches its own browser, so the launch lives here once.
module HeadlessBrowser
  def self.launch(**options)
    options[:browser_options] = (options[:browser_options] || {}).merge("enable-logging" => "stderr")
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    browser = Ferrum::Browser.new(timeout: 20, process_timeout: 30, **options)
    warn format("[headless_browser] %s ready in %.1fs", browser.version.product, Process.clock_gettime(Process::CLOCK_MONOTONIC) - started)
    browser
  rescue Ferrum::ProcessTimeoutError => e
    warn "[headless_browser] Chrome printed this before the launch timed out:\n#{e.output}"
    raise
  end
end
