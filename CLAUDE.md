# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Ruby gem that adds a `mermaid_erd` Rake task to a host Rails app. The task introspects the app's ActiveRecord models and emits a single self-contained HTML file at `<app_root>/mermaid_erd/index.html` containing a Vue 3 + Mermaid.js editor (Tailwind + i18n en/ja, all inlined — no build step). The generated file is meant to be opened directly in a browser or hosted statically.

## Commands

All commands run inside the dev container (`docker compose exec devcontainer ...`) unless noted. The dummy app and CI both run on PostgreSQL 14 (`pg` is the only DB driver wired into the dev container), so the test DB must be Postgres.

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

# Run rspec against one row of the matrix (Rails 7.2 example):
docker compose exec -e BUNDLE_GEMFILE=/workspace/gemfiles/rails_7_2.gemfile devcontainer bundle exec rspec

# Regenerate gemfiles/*.gemfile after editing Appraisals at the repo root:
docker compose exec devcontainer bundle exec appraisal install
```

CI runs natively on GitHub Actions via `ruby/setup-ruby` + `services.postgres` (no `compose.ci.yml` — that file is gone). `compose.yml`/`Dockerfile` are local-dev only and pinned to a single Ruby; the dev container can only exercise matrix rows whose Rails supports that Ruby. The full Ruby × Rails matrix lives in `Appraisals` (repo root) and `.github/workflows/run-test.yml` — keep both in sync. The `gemfiles/*.gemfile` files are committed; their lockfiles are gitignored and resolved fresh per Ruby in CI. Regenerate the gemfiles with `bundle exec appraisal install` after editing `Appraisals`.

## Architecture

- **`lib/rails-mermaid_erd.rb`** — declares the `mermaid_erd` Rake task. It calls `Builder.model_data`, then evaluates `lib/templates/index.html.erb` with `version`, `app_name`, `logo`, and `result` (the schema dump) in scope, and writes the rendered HTML to the path from `Configuration#result_path`. ERB binding is the entire integration contract between Ruby and the front-end.

- **`lib/rails-mermaid_erd/builder.rb`** — the only nontrivial Ruby. Calls `Rails.application.eager_load!`, walks `ActiveRecord::Base.descendants`, and emits `{Models: [...], Relations: [...]}`. Two things to know before touching it:
  1. **Relation deduplication is direction-aware, but the `Line`-style filter is selective.** For each model it iterates `has_many`, `has_and_belongs_to_many`, `belongs_to`, `has_one` and looks up a reverse pair in `Relations` by matching `LeftModelName`/`RightModelName`. The `has_many` and `has_one` branches *also* filter on `Line` style (`".."` for `through:`, `"--"` otherwise — `builder.rb:48-54, 120-126`), so direct and `through:` associations don't collapse into each other. The `belongs_to` (`builder.rb:94`) and `has_and_belongs_to_many` (`builder.rb:76`) branches match on names only — don't add a `Line` filter there, it would break HABTM and BT-vs-pre-existing-HM merges. When a reverse pair is found, the entry is *merged* (the new association name is appended to `Comment`, and cardinality glyphs may upgrade `||` → `|o` for optional `belongs_to`).
  2. **Model name resolution** goes through `get_reflection_model_name`, which honors `class_name:`, then `through:` + `source:`, else falls back to `reflection.class_name`. The dummy app deliberately exercises all three (`Author` is `users`, `comment_posts` is `has_many :through`, `images` uses `class_name: "UserImage"`).

  HABTM join tables emitted by Rails with `HABTM_` in the name and tables that don't exist yet are skipped — don't add filtering elsewhere.

- **`lib/rails-mermaid_erd/configuration.rb`** — reads `config/mermaid_erd.yml` from the host app via `Rails.root`. Only `result_path` exists today; defaults to `mermaid_erd/index.html`. Keep new keys backwards-compatible (the merge happens on top of a hardcoded default hash).

- **`lib/templates/index.html.erb`** — ~870 lines of Vue 3, Mermaid.js, and Tailwind, all in one file. The three front-end bundles are vendored under `lib/templates/vendor/` and inlined at render time (see `RailsMermaidErd.read_gem_asset` in `lib/rails-mermaid_erd.rb`) so the generated HTML has no CDN dependency at runtime — see `lib/templates/vendor/README.md` for the refresh procedure, `CHECKSUMS.txt`, and `LICENSES.md`. Schema is injected via `window.SCHEMA_DATA = <%= result.to_json %>`. UI state (selected models, toggles) is serialized to the URL hash as base64 JSON, so links are shareable. Any new field you add in `Builder` is visible here automatically via that JSON dump — coordinate naming. i18n strings live in the `window.i18n` block; both `en` and `ja` must be kept in sync. Mermaid 10+ made `mermaid.render` asynchronous, so `reRender` must stay `async`/`await`; the call sites are fire-and-forget on purpose.

## Test strategy

`spec/dummy` is a real (minimal) Rails app whose models intentionally cover every association edge case the builder handles — read `spec/dummy/app/models/*.rb` and `spec/dummy/db/schema.rb` as the spec of the spec. When changing `Builder`, the right move is usually to add a model/association to the dummy app and extend `spec/rails-mermaid_erd/builder/model_data_spec.rb` rather than mocking; the expected arrays in that file are exhaustive `match_array` assertions, so additions there are deliberate.

## Contribution conventions

Detailed in `docs/DEVELOPMENT.md` ("Contributing" section). Highlights to apply without re-reading:

- **Language**: every PR title, PR body, issue, commit message, code comment, and `/docs` file is written in **English**. The README is the only bilingual artifact (`README.md` + `README.ja.md` — update both together). UI strings in `lib/templates/index.html.erb` have paired `en`/`ja` entries in the `window.i18n` block; keep them in sync.
- **Branches**: `feature/<kebab-case>` for work, `release/vX.Y.Z` for releases. Target `develop` for everything except the release `→ main` PR.
- **Commit messages**: English, imperative mood, single subject line. **No Conventional Commits prefixes** (`feat:`/`fix:` are not used here). Examples from history: `Add zoom and drag mouse controls`, `Fix a typo`, `Avoid unnecessary loading on Rails boot`. Version-bump commits use the bare subject `vX.Y.Z`, hand-written after `bundle exec bump <level> --no-commit` (see `RELEASE.md`) so the bump can be grouped with the regenerated `docs/example.html` and `docs/screen_shot.png`.
- **PR titles**: same imperative-English style as commits. Release PRs use the fixed title `Release/vX.Y.Z`.
- **PR bodies**: empty bodies are acceptable for small PRs (the merged history confirms this). For non-trivial changes, use the `### Motivation / Background` + `### Detail` structure modeled by [PR #84](https://github.com/koedame/rails-mermaid_erd/pull/84). Attach screenshots for UI changes.

## Release flow

Full procedure in `RELEASE.md`. Two-PR GitFlow pattern: from a single `release/vX.Y.Z` branch, open one PR into `develop` and another into `main` with the title `Release/vX.Y.Z` (empty body OK) — both must merge so the bump lands on both lines. `develop` is the default integration branch; `main` only moves on release. After merging, `rake build` and `rake release` run on the host (not the container) to push to RubyGems. SemVer applies: patch for bug fixes / dependency bumps, minor for backwards-compatible features, major for breaking changes.
