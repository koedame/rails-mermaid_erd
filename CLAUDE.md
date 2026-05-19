# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Ruby gem that adds a `mermaid_erd` Rake task to a host Rails app. The task introspects the app's ActiveRecord models and emits a single self-contained HTML file at `<app_root>/mermaid_erd/index.html` containing a Vue 3 + Mermaid.js editor (Tailwind + i18n en/ja, all inlined — no build step). The generated file is meant to be opened directly in a browser or hosted statically.

## Commands

All commands run inside the dev container (`docker compose exec devcontainer ...`) unless noted. PostgreSQL is required for tests because `Builder` calls `ActiveRecord::Schema.foreign_keys` and `connection.table_comment`.

```bash
# First-time setup (after `docker compose up -d`):
docker compose exec -w /workspace/spec/dummy devcontainer bundle exec rails db:setup RAILS_ENV=test

# Run the full RSpec suite (coverage via SimpleCov drops in /coverage):
docker compose exec devcontainer bundle exec rspec

# Run a single spec file or example:
docker compose exec devcontainer bundle exec rspec spec/rails-mermaid_erd/builder/model_data_spec.rb
docker compose exec devcontainer bundle exec rspec spec/rails-mermaid_erd/builder/model_data_spec.rb:6

# Lint (StandardRb — enforced in CI):
docker compose exec devcontainer bundle exec standardrb
docker compose exec devcontainer bundle exec standardrb --fix

# Exercise the generator end-to-end against the dummy app — writes spec/dummy/mermaid_erd/index.html:
docker compose exec -w /workspace/spec/dummy devcontainer bundle exec rails mermaid_erd RAILS_ENV=test
```

CI (`.github/workflows/run-test.yml`, `coding-style-check.yml`) uses `compose.ci.yml` instead of `compose.yml` — they are not interchangeable (different container names, mount paths, env wiring).

## Architecture

The runtime split is small but worth keeping straight:

- **`lib/rails-mermaid_erd.rb`** — declares the `mermaid_erd` Rake task. It calls `Builder.model_data`, then evaluates `lib/templates/index.html.erb` with `version`, `app_name`, `logo`, and `result` (the schema dump) in scope, and writes the rendered HTML to the path from `Configuration#result_path`. ERB binding is the entire integration contract between Ruby and the front-end.

- **`lib/rails-mermaid_erd/builder.rb`** — the only nontrivial Ruby. Calls `Rails.application.eager_load!`, walks `ActiveRecord::Base.descendants`, and emits `{Models: [...], Relations: [...]}`. Two things to know before touching it:
  1. **Relation deduplication is direction-aware.** For each model it iterates `has_many`, `has_and_belongs_to_many`, `belongs_to`, `has_one` and checks `Relations` for a reverse pair (matching `LeftModelName`/`RightModelName` and the `Line` style `--` vs `..`). If found, it *merges* (appends the new association name into `Comment`, possibly upgrades cardinality glyphs like `||` → `|o` for optional `belongs_to`). If not, it appends a new tuple. The `Line: ".."` vs `"--"` distinction is how `through:` associations stay separate from direct ones.
  2. **Model name resolution** goes through `get_reflection_model_name`, which honors `class_name:`, then `through:` + `source:`, else falls back to `reflection.class_name`. The dummy app deliberately exercises all three (`Author` is `users`, `comment_posts` is `has_many :through`, `images` uses `class_name: "UserImage"`).

  HABTM join tables emitted by Rails with `HABTM_` in the name and tables that don't exist yet are skipped — don't add filtering elsewhere.

- **`lib/rails-mermaid_erd/configuration.rb`** — reads `config/mermaid_erd.yml` from the host app via `Rails.root`. Only `result_path` exists today; defaults to `mermaid_erd/index.html`. Keep new keys backwards-compatible (the merge happens on top of a hardcoded default hash).

- **`lib/templates/index.html.erb`** — ~870 lines of Vue 3 (CDN), Mermaid.js, and Tailwind, all in one file. Schema is injected via `window.SCHEMA_DATA = <%= result.to_json %>`. UI state (selected models, toggles) is serialized to the URL hash as base64 JSON, so links are shareable. Any new field you add in `Builder` is visible here automatically via that JSON dump — coordinate naming. i18n strings live in the `window.i18n` block; both `en` and `ja` must be kept in sync.

## Test strategy

`spec/dummy` is a real (minimal) Rails app whose models intentionally cover every association edge case the builder handles — read `spec/dummy/app/models/*.rb` and `spec/dummy/db/schema.rb` as the spec of the spec. When changing `Builder`, the right move is usually to add a model/association to the dummy app and extend `spec/rails-mermaid_erd/builder/model_data_spec.rb` rather than mocking; the expected arrays in that file are exhaustive `match_array` assertions, so additions there are deliberate.

## Contribution conventions

Detailed in `docs/DEVELOPMENT.md` ("Contributing" section). Highlights to apply without re-reading:

- **Language**: every PR title, PR body, issue, commit message, code comment, and `/docs` file is written in **English**. The README is the only bilingual artifact (`README.md` + `README.ja.md` — update both together). UI strings in `lib/templates/index.html.erb` have paired `en`/`ja` entries in the `window.i18n` block; keep them in sync.
- **Branches**: `feature/<kebab-case>` for work, `release/vX.Y.Z` for releases. Target `develop` for everything except the release `→ main` PR.
- **Commit messages**: English, imperative mood, single subject line. **No Conventional Commits prefixes** (`feat:`/`fix:` are not used here). Examples from history: `Add zoom and drag mouse controls`, `Migrate to Docker Compose V2`, `Fix a typo`. Version-bump commits are bare `vX.Y.Z`.
- **PR titles**: same imperative-English style as commits. Release PRs use the fixed title `Release/vX.Y.Z`.
- **PR bodies**: empty bodies are acceptable for small PRs (the merged history confirms this). For non-trivial changes, use the `### Motivation / Background` + `### Detail` structure modeled by [PR #84](https://github.com/koedame/rails-mermaid_erd/pull/84). Attach screenshots for UI changes.

## Release flow

Full procedure in `RELEASE.md`. Two-PR GitFlow pattern: from a single `release/vX.Y.Z` branch, open one PR into `develop` and another into `main` with the title `Release/vX.Y.Z` (empty body OK) — both must merge so the bump lands on both lines. `develop` is the default integration branch; `main` only moves on release. After merging, `rake build` and `rake release` run on the host (not the container) to push to RubyGems. SemVer applies: patch for bug fixes / dependency bumps, minor for backwards-compatible features, major for breaking changes.
