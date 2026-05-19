# Rails Mermaid ERD Developer Documentation

## Project Overview
Rails Mermaid ERD is a Ruby gem that generates Mermaid format ER diagrams from Ruby on Rails applications. The generated ERD can be copied in Markdown format for easy sharing on GitHub and can also be saved as images.

## Technology Stack
### Backend
- Ruby on Rails (>= 5.2)
- PostgreSQL 14 (Test database)

### Frontend
- Vue.js 3.2.40
- Mermaid.js 9.1.7 (ERD generation)
- TailwindCSS 3.1.8
  - Forms plugin 0.5.2
  - Typography plugin 0.5.4

### Development Environment
- Docker/Docker Compose V2
- Alpine Linux (Base container image)

## Development Environment Setup

### Prerequisites
- Docker
- Docker Compose V2

### Setup Instructions

1. Clone the repository
```bash
git clone https://github.com/koedame/rails-mermaid_erd.git
cd rails-mermaid_erd
```

2. Build and start the Docker environment
```bash
docker compose up -d
```

Note: The initial build may take several minutes as it needs to install system dependencies in the Alpine Linux container.

3. Setup the test database
```bash
# Load schema.rb into the test database for the dummy application
docker compose exec -w /workspace/spec/dummy devcontainer bundle exec rails db:setup RAILS_ENV=test
```

`db:setup` runs `db:schema:load`, which matches what `.github/workflows/run-test.yml` does in CI.

4. Run tests to verify the setup
```bash
docker compose exec devcontainer bundle exec rspec
```

If all tests pass and you see a coverage report, your development environment is ready.

## Project Structure
- `/lib`: Main gem code
  - `/lib/rails-mermaid_erd`: Core gem implementation
  - `/lib/rails-mermaid_erd/version.rb`: Gem version definition
- `/spec`: Test files
  - `/spec/dummy`: Test Rails application with sample models
    - Contains User, Post, Comment, and other models for testing
- `/docs`: Documentation
- `/.github`: GitHub Actions configuration
- `/.devcontainer`: Development container settings

## Dependencies
### Production
- rails (>= 5.2)

### Development
- pg (PostgreSQL client)
- rspec-rails (Testing framework)
- simplecov (Code coverage)
- standard (Code style)
- tzinfo-data (Timezone data)

## Docker Configuration
The project includes several Docker-related files:
- `compose.yml`: Main development environment configuration
  - `devcontainer`: Ruby development environment (Alpine Linux based)
  - `db`: PostgreSQL 14 database for testing
- `compose.ci.yml`: CI environment configuration
- `Dockerfile`: Development container definition
- `Dockerfile.ci`: CI container definition

### Database Configuration
The test database is configured with the following credentials:
- Host: `db`
- User: `test`
- Password: `test`
- Database: `dummy_test` (for the dummy Rails application)

### Environment Variables
The following environment variables are automatically set in the development container:
- `POSTGRES_HOST`: db
- `POSTGRES_USER`: test
- `POSTGRES_PASSWORD`: test
- `RAILS_ENV`: test

### Common Docker Commands
```bash
# Start the development environment
docker compose up -d

# View logs
docker compose logs -f

# Stop the environment
docker compose down

# Rebuild containers
docker compose build --no-cache

# Run tests in container
docker compose exec devcontainer bundle exec rspec

# Access container shell
docker compose exec devcontainer sh
```

## Development Workflow
1. Make changes to the gem code in `/lib`
2. Write tests in `/spec`
3. Run tests to verify changes
4. Update documentation if necessary

### Testing
The gem includes a dummy Rails application in `/spec/dummy` for testing purposes. This application includes several models (User, Post, Comment, etc.) to test the ERD generation functionality.

To run the tests:
```bash
docker compose exec devcontainer bundle exec rspec
```

The test suite includes coverage reporting via SimpleCov. The coverage report will be generated in the `/coverage` directory.

## License
This project is released under the MIT License.

## Contributing

The `develop` branch is the default integration branch; `main` only ever moves on release. All feature work targets `develop`.

### Branch naming
Pick the prefix that matches the change:

| Purpose      | Pattern                  | Example                                |
| ------------ | ------------------------ | -------------------------------------- |
| New feature  | `feature/<kebab-case>`   | `feature/improve-erd-viewer-operation` |
| Release      | `release/vX.Y.Z`         | `release/v0.6.0`                       |
| Dependabot   | (auto-generated)         | `dependabot/bundler/rails-8.0.1`       |

Outside contributors occasionally use bare slugs (e.g. `typo`, `readme-require-false`); maintainers keep the `feature/` prefix.

### Commit messages
- **English, imperative mood, single subject line.** No body unless truly needed.
- **No Conventional Commits prefix** (`feat:`, `fix:`, …) — the history doesn't use them. The one `docs:` example in `git log` is the exception, not the rule.
- Examples drawn from merged history:
  - `Add zoom and drag mouse controls`
  - `Migrate to Docker Compose V2` (PR title) → underlying commits `Rename compose files for Docker Compose V2`, `Update GitHub Actions workflows for Docker Compose V2`, `Add development documentation`, `Remove .devcontainer`
  - `Fix a typo`
  - `Avoid unnecessary loading on Rails boot`
  - `Add control hints`
- Version-bump commits use the bare subject `vX.Y.Z` (e.g. `v0.6.0`). They are written by hand after `bundle exec bump <level> --no-commit` so the bump can be grouped with the regenerated `docs/example.html` and `docs/screen_shot.png` — see `RELEASE.md`.

### Pull requests
- **Title**: same imperative-English convention as commits. The PR title is what reviewers and changelog readers see, so make it specific (`Add zoom and drag mouse controls`, not `Update viewer`).
- **Base branch**: `develop` for everything except the release `→ main` PR (see `RELEASE.md`).
- **Body**: small PRs ship with an empty body; that is accepted practice here. For anything non-trivial, follow the structure used in PR #84 ([Add table comments to SCHEMA_DATA.Models](https://github.com/koedame/rails-mermaid_erd/pull/84)):
  ```markdown
  ### Motivation / Background
  <why this change is needed — link Rails docs / issues if relevant>

  ### Detail
  <what changed and any design notes a reviewer needs>
  ```
  For UI-affecting changes, attach a screenshot or short clip (PR #95 is an example).
- **One PR ≈ one concern.** Multi-step refactors like #136 list the bullets in the body but stay scoped to a single theme.

### Natural language
All public-facing development artifacts are written in **English**:
- Pull Request titles and descriptions
- Issue titles and descriptions
- Commit messages
- Code comments, identifier names, and documentation under `/docs`

The README is bilingual (`README.md` / `README.ja.md`); when you change one, update the other in the same PR. UI strings in `lib/templates/index.html.erb` live in the `window.i18n` block and must be kept in sync between `en` and `ja`.

## CI/CD
Three GitHub Actions workflows run on each contribution:

| Workflow                                    | Triggers                                              | What it runs                                                |
| ------------------------------------------- | ----------------------------------------------------- | ----------------------------------------------------------- |
| `.github/workflows/run-test.yml`            | push / PR to `main` or `develop`                      | `bundle exec rspec` against the dummy app on PostgreSQL 14  |
| `.github/workflows/coding-style-check.yml`  | push / PR to `main` or `develop`                      | `bundle exec standardrb` (StandardRb)                       |
| `.github/workflows/codeql-analysis.yml`     | push / PR to `develop`, plus a weekly cron            | CodeQL Ruby analysis                                        |

The first two use `compose.ci.yml` (not `compose.yml`). Dependabot watches three ecosystems — Docker, Bundler, and GitHub Actions (see `.github/dependabot.yml`) — and its PRs are merged once CI is green.

## Development Best Practices
1. Add or extend tests in `spec/` before changing `Builder` behavior. The dummy app's models (`spec/dummy/app/models/*.rb`) are the contract — extend them to cover new association cases.
2. Run `bundle exec standardrb` (or `--fix`) before pushing; CI fails on style violations.
3. Update documentation in the same PR as the code change, including the bilingual README pair when relevant.
4. Keep PRs focused on a single concern; split unrelated refactors into separate branches.
5. Write all development communication in English (see [Natural language](#natural-language)).

## Troubleshooting

### Common Issues

1. Container fails to start or stops immediately
```bash
# Check the container logs
docker compose logs devcontainer
docker compose logs db
```

2. Database connection issues
```bash
# Verify the database is running
docker compose ps

# Reset the database
docker compose exec -w /workspace/spec/dummy devcontainer bundle exec rails db:reset RAILS_ENV=test
```

3. Bundle install fails
```bash
# Remove the bundle volume and try again
docker compose down -v
docker compose up -d
docker compose exec devcontainer bundle install
```

### Full Environment Reset
If you encounter persistent issues, you can completely reset the development environment:

```bash
# Remove all containers and volumes
docker compose down -v

# Rebuild from scratch
docker compose up -d --build

# Reinstall dependencies
docker compose exec devcontainer bundle install

# Reset test database
docker compose exec -w /workspace/spec/dummy devcontainer bundle exec rails db:reset RAILS_ENV=test
```

## Contact
For issues or questions, please create a GitHub Issue.
