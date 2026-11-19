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
```

`docs/images/hero.png` (the README hero) is a fixed image and is not regenerated per release. Retake it only when the viewer's look changes: open `docs/example.html` with the Author, Post, Bookmark, Tag and AuthorProfile models selected, Columns set to Keys Only and Show Key on, in a 1600 × 760 window at 1.5× scale (2400 × 1140 px), with the browser language set to English.

Stage the bump and the regenerated demo, then commit them together with the message `vX.Y.Z` (matching prior history: `v0.6.0`, `v0.5.1`, …):

```bash
git add lib/rails-mermaid_erd/version.rb Gemfile.lock docs/example.html
git commit -m "vX.Y.Z"
```

`Gemfile.lock` updates because the gemspec version flows into it on `bundle install`. Past release commits (`v0.6.0`, `v0.5.1`, `v0.5.0`) include the same paths, plus `docs/screen_shot.png` before it was replaced by the static `docs/images/hero.png`.

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

### 5. Publish the GitHub Release

`rake release` only pushes the git tag — it does not create the GitHub Releases entry. Create it explicitly so the tag shows up on https://github.com/koedame/rails-mermaid_erd/releases.

The release notes must **never include release-PR rows** — both the modern `Release/vX.Y.Z by …` form and the legacy bare `vX.Y.Z by …` form (used once, for the v0.1.2 row in v0.2.0's notes). They are noise: the release branch is the delivery mechanism, not a change. Because GitHub's auto-generated notes always list those PRs, filter them out before publishing:

```bash
# 1. Ask the GitHub API for the auto-generated notes for this tag.
# 2. Drop any release-PR row (both `Release/vX.Y.Z by …` and bare `vX.Y.Z by …`).
# 3. Publish with the filtered body.
gh api repos/koedame/rails-mermaid_erd/releases/generate-notes \
  -f tag_name=vX.Y.Z \
  -f previous_tag_name=vPREV.Y.Z \
  --jq .body \
  | grep -v -E '^\* (Release/)?v[0-9]+\.[0-9]+\.[0-9]+ by ' \
  > /tmp/release-notes.md

gh release create vX.Y.Z --title vX.Y.Z --notes-file /tmp/release-notes.md --verify-tag
```

Skim the published page to confirm the body lists only feature/fix/dependency PRs. Historical releases through `v0.7.0` were retroactively cleaned to match this rule — keep them that way.
