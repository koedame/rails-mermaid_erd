require "spec_helper"
require "open3"
require "rbconfig"

# Rails 7.2 added `ActiveRecord.permanent_connection_checkout`. With
# `:disallowed` an application may not call `ActiveRecord::Base.connection` at
# all, and `:deprecated` warns (raising once the deprecator is set to `:raise`).
describe RailsMermaidErd::Builder do
  describe ".model_data with permanent_connection_checkout restricted" do
    # Run in a fresh process. The example's own process already holds a
    # connection for its transactional fixtures, and a held connection is
    # reused by `connection`, which would hide the very call under test. The
    # setting is also process-wide, so it must not leak into other examples.
    script = <<~RUBY
      require File.expand_path("spec/dummy/config/environment", Dir.pwd)

      ActiveRecord.permanent_connection_checkout = ARGV.fetch(0).to_sym
      ActiveRecord.deprecator.behavior = :raise

      abort "a connection was already checked out before the build" if ActiveRecord::Base.connection_pool.active_connection?

      puts RailsMermaidErd::Builder.model_data[:Models].map { |model| model[:ModelName] }.sort.join(",")
    RUBY

    [:disallowed, :deprecated].each do |mode|
      context "when the mode is #{mode}" do
        it "builds the models without checking out a permanent connection" do
          skip "Rails #{Rails::VERSION::STRING} has no permanent_connection_checkout" unless ActiveRecord.respond_to?(:permanent_connection_checkout=)

          output, status = Open3.capture2e(
            {"RAILS_ENV" => "test"}, RbConfig.ruby, "-e", script, mode.to_s,
            chdir: File.expand_path("../../..", __dir__)
          )

          expect(status).to be_success, output
          expect(output.lines.last.split(",")).to include("Author", "Post", "Comment")
        end
      end
    end
  end
end
