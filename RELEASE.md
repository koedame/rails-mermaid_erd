

## Perform a release

in docekr devcontainer:

```bash
cd /workspace && bundle install

cd /workspace && bundle exec bump patch --no-commit
# or
cd /workspace && bundle exec bump minor --no-commit
# or
cd /workspace && bundle exec bump major --no-commit

cd /workspace && bundle exec rspec
cd /workspace/spec/dummy && RAILS_ENV=test bundle exec rails mermaid_erd
cp -f /workspace/spec/dummy/mermaid_erd/index.html /workspace/docs/example.html
```

in host machine:

```bash
bundle install
bundle exec rake build
bundle exec rake release
```
