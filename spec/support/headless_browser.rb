require "ferrum"

# Starts the headless Chrome the viewer specs drive. Every viewer spec file
# launches its own browser, so the launch lives here once.
module HeadlessBrowser
  def self.launch(**options)
    Ferrum::Browser.new(timeout: 20, process_timeout: 30, **options)
  rescue Ferrum::ProcessTimeoutError => e
    # Ferrum keeps what Chrome printed on the error but leaves it out of the message.
    warn "Chrome printed this before the launch timed out:\n#{e.output}"
    raise
  end
end
