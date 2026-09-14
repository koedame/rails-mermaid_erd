# Per-Rails Gemfiles for matrix testing. Regenerate with:
#   bundle exec appraisal install
# When adding or removing an `appraise` block, also update the
# `matrix.include:` list in .github/workflows/run-test.yml so CI exercises
# the new row.
#
# Compatibility pins below are workarounds, not preferences. Each pin
# carries the reason it exists and the condition for removal.

# concurrent-ruby 1.3.5 removed its runtime dependency on the stdlib
# `logger`, which Rails <= 7.0 implicitly relies on. Remove the pin once
# the project drops support for the affected Rails versions.
# Reference: https://github.com/rails/rails/issues/54260
CONCURRENT_RUBY_LOGGER_PIN = "< 1.3.5"

# Psych 4 changed YAML.load to default-safe-load, breaking Rails 5.2 /
# 6.0 boot (they pass aliases that the safe loader rejects). Rails 6.1+
# handles psych 4. Remove once 5.2 / 6.0 are dropped from the matrix.
# Reference: https://github.com/rails/rails/issues/43335
PSYCH_SAFE_LOAD_PIN = "< 4"

appraise "rails-5-2" do
  gem "rails", "~> 5.2.0"
  gem "concurrent-ruby", CONCURRENT_RUBY_LOGGER_PIN
  gem "psych", PSYCH_SAFE_LOAD_PIN
  # rspec-rails 5+ requires Rails >= 5.2 but its constraints conflict with
  # Rails 5.2 patch releases; pin to the 4.x line that explicitly supports it.
  gem "rspec-rails", "~> 4.1"
end

appraise "rails-6-0" do
  gem "rails", "~> 6.0.0"
  gem "concurrent-ruby", CONCURRENT_RUBY_LOGGER_PIN
  gem "psych", PSYCH_SAFE_LOAD_PIN
  gem "rspec-rails", "~> 4.1"
end

appraise "rails-6-1" do
  gem "rails", "~> 6.1.0"
  gem "concurrent-ruby", CONCURRENT_RUBY_LOGGER_PIN
  # rspec-rails 6 dropped Rails 6.0 but still supports 6.1.
  gem "rspec-rails", "~> 6.0"
end

appraise "rails-7-0" do
  gem "rails", "~> 7.0.0"
  gem "concurrent-ruby", CONCURRENT_RUBY_LOGGER_PIN
end

appraise "rails-7-1" do
  gem "rails", "~> 7.1.0"
end

appraise "rails-7-2" do
  gem "rails", "~> 7.2.0"
end

appraise "rails-8-0" do
  gem "rails", "~> 8.0.0"
end

appraise "rails-8-1" do
  gem "rails", "~> 8.1.0"
end
