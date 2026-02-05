# gem/AGENTS.md

This directory contains the **Ruby Client** implementation for Exots.

## Tech Stack
- **Language:** Ruby
- **Package Manager:** `bundler`
- **Testing:** `rspec`

## Key Commands
- **Install:** `bundle install`
- **Test:** `bundle exec rspec`
- **Pack:** `bundle exec rake pack` (Automatically includes root `LICENSE` and `README.md`)

## Development Workflow
1.  Make changes to the Ruby code in `lib/`.
2.  Run tests: `bundle exec rspec`.
3.  If adding new dependencies, update `exots.gemspec` and run `bundle install`.
4.  To release/distribute, run `bundle exec rake pack`.

Note: Do not manually edit `gem/LICENSE` or `gem/README.md`. These are automatically copied from the project root during the build process.
