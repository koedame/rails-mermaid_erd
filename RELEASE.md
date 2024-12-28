## Perform a release

```bash
git checkout -b release/vx.x.x
```

in docekr devcontainer:

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
chromium-browser --headless --disable-gpu --no-sandbox --window-size=1280,800 --hide-scrollbars --screenshot="/workspace/docs/screen_shot.png" /workspace/spec/dummy/mermaid_erd/index.html
```

in host machine:

```bash
bundle install
bundle exec rake build
bundle exec rake release
```
