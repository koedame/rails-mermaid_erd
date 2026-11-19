[English](./README.md) | [日本語](./README.ja.md) | [简体中文](./README.zh-CN.md) | [繁體中文](./README.zh-TW.md) | [한국어](./README.ko.md) | [Español](./README.es.md) | [Français](./README.fr.md) | [Deutsch](./README.de.md) | [Italiano](./README.it.md) | [Português (Brasil)](./README.pt-BR.md) | [Русский](./README.ru.md) | [العربية](./README.ar.md)

<div align="center">

# Rails Mermaid ERD

**Generate an interactive Mermaid ERD of your Rails app as a single self-contained HTML file.**

<a href="https://koedame.github.io/rails-mermaid_erd/example.html"><img alt="The Rails Mermaid ERD viewer showing five models with their primary and foreign keys, linked by relationship lines." src="docs/images/hero.png" width="880"></a>

[![test](https://github.com/koedame/rails-mermaid_erd/actions/workflows/run-test.yml/badge.svg)](https://github.com/koedame/rails-mermaid_erd/actions/workflows/run-test.yml)
[![Gem Version](https://img.shields.io/gem/v/rails-mermaid_erd?color=dc2626)](https://rubygems.org/gems/rails-mermaid_erd)
![Rails 5.2 – 8.1](https://img.shields.io/badge/rails-5.2%20%E2%80%93%208.1-dc2626)
![License: MIT](https://img.shields.io/badge/license-MIT-dc2626)

[Demo Page](https://koedame.github.io/rails-mermaid_erd/example.html) · [Installation](#installation) · [Usage](#usage) · [Supported versions](#supported-versions) · [Configuration](#configuration)

</div>

Run `rails mermaid_erd` and get a single self-contained HTML file with your Rails schema — no extra gems or services. Tailwind, Mermaid and Vue are embedded in it, so it opens offline and behind a corporate proxy. In the browser, pick the tables you want and export them as Mermaid code, SVG or PNG; to share the diagram, hand over the HTML file or put it on a web server.

## Highlights

- **One file, nothing else to install.** The output is a single ~4 MB HTML file with Tailwind, Mermaid and Vue inlined, so it opens offline and behind a corporate proxy.
- **Draw only what you need.** Select models, show all columns, keys only or none, and add comments and relationship labels.
- **Export and share.** Copy Mermaid or Markdown code, download SVG or PNG, or copy a link that restores your view.
- **Wide Rails support.** CI covers Rails 5.2 through 8.1 on Ruby 2.7 through 4.0.
- **12 languages.** The viewer follows your browser language, including right-to-left Arabic.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "rails-mermaid_erd", group: :development, require: false
```

And then execute:

```bash
bundle install
```

Add this line to your application's Rakefile:

```ruby
begin
  require "rails-mermaid_erd"
rescue LoadError
  # Do nothing.
end
```

## Usage

Run rake task `mermaid_erd` will generate `<app_root>/mermaid_erd/index.html`.

```bash
bundle exec rails mermaid_erd
# or
bundle exec rake mermaid_erd
```

Simply open the generated `<app_root>/mermaid_erd/index.html` in your browser.

This file is not required for Git management, so you can add it to `.gitignore` if necessary

```.gitignore
mermaid_erd
```

`<app_root>/mermaid_erd/index.html` is a single self-contained HTML file. All front-end dependencies (Tailwind, Mermaid, Vue) are inlined, so it works offline and behind strict corporate proxies — no CDN access is needed at view time. The file is roughly 4 MB because the bundles ship inside it.

If you share this file, it can be used by those who do not have a Ruby on Rails environment. Or, you can upload the file to a web server and share it with the same URL.

The generated file contains your application's schema, including table and column names and comments. Share it, or host it, only as widely as you would share the schema itself.

It would be very smart to generate it automatically using CI.

### Print the Mermaid source to stdout

Run rake task `mermaid_erd:print` to print the raw `erDiagram` source to stdout instead of writing the HTML viewer. This pipes cleanly into other tools:

```bash
bundle exec rails mermaid_erd:print
bundle exec rails mermaid_erd:print > er.mmd
bundle exec rails mermaid_erd:print | mmdc -i - -o er.svg
```

The output is the full diagram — every table, column, key, comment, and relation — equivalent to the HTML viewer with all of its detail toggles enabled.

## Languages

The viewer UI ships in 12 languages: English, 日本語, 简体中文, 繁體中文, 한국어, Español, Français, Deutsch, Italiano, Português (Brasil), Русский, and العربية (right-to-left). It auto-detects the browser language (`navigator.language`) on load, falls back to English for unsupported locales, and can be switched manually from the selector in the top-right corner.

## Supported versions

The Ruby × Rails combinations exercised by CI on every push and pull request:

| Rails | Ruby                             |
| ----- | -------------------------------- |
| 5.2   | 2.7                              |
| 6.0   | 2.7, 3.0                         |
| 6.1   | 2.7, 3.0, 3.1, 3.2, 3.3          |
| 7.0   | 2.7, 3.0, 3.1, 3.2, 3.3          |
| 7.1   | 3.1, 3.2, 3.3, 3.4               |
| 7.2   | 3.1, 3.2, 3.3, 3.4               |
| 8.0   | 3.2, 3.3, 3.4, 4.0               |
| 8.1   | 3.2, 3.3, 3.4, 4.0               |

Other combinations may work but are not verified.

## Configuration

`./config/mermaid_erd.yml` to customize the configuration.
See [./docs/example.yml](./docs/example.yml) for an example configuration.

The setting items are as follows.

| key | description | default |
| --- | --- | --- |
| `result_path` | Destination of generated files. | `mermaid_erd/index.html` |
| `ignore_tables` | Array of regular-expression strings. Tables whose `table_name` matches any pattern are dropped from the generated ERD, along with any relations that point at them. Useful for excluding audit-log models, soft-deleted/legacy tables, or other large noise you don't want to render. Patterns are compiled with `Regexp.new`, so escape backslashes inside YAML strings (e.g. `"\\Aaudit_"`). | `[]` |
| `viewer_defaults` | The view the viewer opens on when the URL carries no saved state, and the one **Reset** returns to; a link with its own state always wins. `models`: array of model names selected at first (a name that is not in the diagram is skipped with a warning when the file is generated). `columns`: `all`, `keys` (primary and foreign keys only) or `none`, the same choices as Columns in the sidebar. Useful for opening a large app on the models people usually start from. | `models: []` (nothing selected), `columns: all` |

<!--
TODO:
## Contributing

Contribution directions go here.
-->

## Trademarks

This project is not affiliated with, endorsed by, or sponsored by Rails, The Rails Foundation, the Mermaid project, or Mermaid Chart Inc. Rails and Ruby on Rails are registered trademarks of David Heinemeier Hansson. Mermaid Chart Inc. has registered or applied for the trademarks MERMAID CHART and MERMAID in the United States. All other trademarks are the property of their respective owners.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
