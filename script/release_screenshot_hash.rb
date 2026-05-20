#!/usr/bin/env ruby
# frozen_string_literal: true

# Build the URL hash that the front-end's restoreFromHash() expects, pre-seeded
# with every model in the generated schema. Used by RELEASE.md so the release
# screenshot captures the rendered ERD instead of the "No models selected"
# placeholder (the default since #169).
#
# Usage:
#   ruby script/release_screenshot_hash.rb <path-to-generated-index.html>

require "json"
require "base64"

# Slice the SCHEMA_DATA object literal from the generated HTML by walking braces
# while tracking JSON string state. A naive regex like `\{.*?\}\s*<\/script>` is
# unsafe: Ruby's `to_json` does not escape `</script>` inside string values, so
# a user model/column/table comment containing `}</script>` would truncate the
# capture and break JSON.parse. Brace-walking with string awareness handles
# that input correctly.
def extract_schema_json(html)
  marker = html.index("window.SCHEMA_DATA")
  raise "SCHEMA_DATA assignment not found in #{html.length}-byte HTML" unless marker

  start = html.index("{", marker)
  raise "SCHEMA_DATA opening brace not found" unless start

  depth = 0
  in_string = false
  escape = false
  i = start
  while i < html.length
    c = html[i]
    if escape
      escape = false
    elsif in_string
      case c
      when "\\" then escape = true
      when '"' then in_string = false
      end
    else
      case c
      when '"' then in_string = true
      when "{" then depth += 1
      when "}"
        depth -= 1
        return html[start..i] if depth.zero?
      end
    end
    i += 1
  end
  raise "SCHEMA_DATA closing brace not found (unbalanced JSON)"
end

input_path = ARGV[0] or abort "usage: #{$PROGRAM_NAME} <path-to-index.html>"
html = File.read(input_path)
data = JSON.parse(extract_schema_json(html))

models = data.fetch("Models").map { |m| m.fetch("ModelName") }
# Empty selection would silently produce the same blank "No models selected"
# screenshot the release flow is trying to avoid — fail loudly instead.
raise "no models found in #{input_path}; refusing to emit an empty selection" if models.empty?

print Base64.strict_encode64(JSON.generate(selectModels: models))
