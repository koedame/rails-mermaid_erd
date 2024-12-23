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
# Create and migrate the test database for the dummy application
docker compose exec -w /workspace/spec/dummy devcontainer bundle exec rails db:create db:migrate RAILS_ENV=test
```

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
docker compose exec devcontainer
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
1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Create a Pull Request

## CI/CD
GitHub Actions automates the following checks:
- Test execution
- Code style verification
- Version management

## Development Best Practices
1. Write tests before modifying code
2. Follow StandardRb coding conventions
3. Update documentation
4. Update CHANGELOG.md

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
