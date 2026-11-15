#!/usr/bin/env bash
# Follows the README's Installation section on a fresh Rails app: the Rakefile
# is taken verbatim from the README's `# Rakefile` code block, so a README that
# no longer works fails here.
set -euo pipefail

gem_root=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

ruby -e '
  block = File.read(ARGV[0])[/^```ruby\n(# Rakefile\n.*?)^```$/m, 1]
  abort "README.md has no `# Rakefile` code block" unless block
  File.write(ARGV[1], block)
' "$gem_root/README.md" "$work/Rakefile.from_readme"

cd "$work"
gem install rails --no-document
rails new blog --minimal --skip-git --skip-bundle -d sqlite3 -q
cd blog
echo "gem \"rails-mermaid_erd\", path: \"$gem_root\", group: :development, require: false" >> Gemfile
bundle install --quiet
bin/rails g model Team name:string >/dev/null
bin/rails g model User team:references email:string >/dev/null
bin/rails db:migrate >/dev/null

cp "$work/Rakefile.from_readme" Rakefile
bundle exec rails mermaid_erd
test -s mermaid_erd/index.html
bundle exec rails mermaid_erd:print | grep -q erDiagram
echo "OK: README's Rakefile works on $(bin/rails --version)"
