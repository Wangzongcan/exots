# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2024-02-05

### Added
- Initial release of **Exots** (Exo-Typescript).
- **Core Architecture**: Host (Ruby) / Plugin (Node.js) model using Unix Domain Sockets.
- **Protocol**: JSON-RPC 2.0 over HTTP (UDS).
- **Ruby Gem**: `exots` (Client/Process Manager).
- **NPM Package**: `exots` (Server/Bridge).
- Support for `bun` and `node` runtimes.
- Basic error handling and exception mapping from JS to Ruby.
