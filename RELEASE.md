## Perform a release

The flow is GitFlow-style. Two PRs are opened from the same `release/vX.Y.Z` branch — one back into `develop`, one into `main` — so the version bump lands on both lines and `main` only ever advances on release. See merged PR pairs `#139`/`#140` (v0.6.0), `#127`/`#128` (v0.5.1), `#96`/`#97` (v0.5.0) for the pattern.

Version bumping follows SemVer:
- `patch` — bug fixes, dependency bumps, no API change
- `minor` — new features that stay backwards-compatible (the default for most feature PRs in history)
- `major` — breaking changes to the gem's public surface or generated output

### 1. Cut the release branch

```bash
git checkout develop
git pull
git checkout -b release/vX.Y.Z
```

### 2. Bump, test, and regenerate the demo (inside the dev container)

```bash
bundle install
bundle clean --force

bundle exec bump patch --no-commit
# or
bundle exec bump minor --no-commit
# or
bundle exec bump major --no-commit

cd /workspace/spec/dummy
RAILS_ENV=test bundle exec rails db:setup
cd /workspace/
bundle exec rspec
cd /workspace/spec/dummy
RAILS_ENV=test bundle exec rails mermaid_erd
cp -f /workspace/spec/dummy/mermaid_erd/index.html /workspace/docs/example.html

# Build a URL hash that pre-selects every model, so the screenshot shows the
# rendered ERD instead of the "No models selected" placeholder (default since
# #169). See script/release_screenshot_hash.rb for details — the script also
# fails loudly if no models are found, so the release maintainer never silently
# commits a blank screenshot.
# The `|| exit 1` is load-bearing: `HASH=$(...)` does NOT propagate the
# sub-shell's exit status, so without it a failed script (e.g. zero models in
# the host app) would leave HASH empty and the chromium-browser call below
# would happily screenshot the empty placeholder.
HASH=$(ruby /workspace/script/release_screenshot_hash.rb /workspace/spec/dummy/mermaid_erd/index.html) || exit 1
# --virtual-time-budget advances Chromium's virtual clock then snapshots; it is
# not a render barrier on Mermaid's async render(). 10s is generous for the
# dummy schema (12 models) — bump if you ever point this at a much larger app.
chromium-browser --headless --disable-gpu --no-sandbox \
  --window-size=1280,800 --hide-scrollbars \
  --virtual-time-budget=10000 \
  --screenshot="/workspace/docs/screen_shot.png" \
  "file:///workspace/spec/dummy/mermaid_erd/index.html#${HASH}"
```

Stage the bump, the regenerated demo, and the screenshot, then commit them together with the message `vX.Y.Z` (matching prior history: `v0.6.0`, `v0.5.1`, …):

```bash
git add lib/rails-mermaid_erd/version.rb Gemfile.lock docs/example.html docs/screen_shot.png
git commit -m "vX.Y.Z"
```

`Gemfile.lock` updates because the gemspec version flows into it on `bundle install`. Past release commits (`v0.6.0`, `v0.5.1`, `v0.5.0`) all include the same four paths.

### 3. Open the two release PRs

Push the branch and open both PRs with the title `Release/vX.Y.Z` (body can be empty — the diff speaks for itself):

```bash
git push -u origin release/vX.Y.Z
gh pr create --base develop --head release/vX.Y.Z --title "Release/vX.Y.Z" --body ""
gh pr create --base main    --head release/vX.Y.Z --title "Release/vX.Y.Z" --body ""
```

Wait for CI (`test`, `coding-style-check`) to pass on both, then merge them. Merge order doesn't matter as long as both land.

### 4. Publish the gem (on the host machine, not in the container)

```bash
git checkout main
git pull
bundle install
bundle exec rake build
bundle exec rake release
```

`rake release` tags the commit as `vX.Y.Z` and pushes to RubyGems. After release, confirm the new version at https://rubygems.org/gems/rails-mermaid_erd.
