# Project Structure

This project is organized as a monorepo containing both the Node.js implementation and the Ruby implementation.

## Directory Layout

```text
exots/
├── npm/                 # Node.js Package Source
│   ├── src/             # TypeScript source code
│   │   ├── index.ts     # Entry point
│   │   └── server.ts    # HTTP/UDS Server implementation
│   ├── package.json
│   └── tsconfig.json
│
├── gem/                 # Ruby Gem Source
│   ├── lib/
│   │   ├── exots.rb     # Gem entry point
│   │   └── exots/
│   │       └── client.rb # Client implementation
│   └── exots.gemspec
│
└── README.md            # Project Documentation
```

## Module Responsibilities

- **npm/**: Handles the "Server" side. Responsible for socket lifecycle management (creation, binding, cleanup) and request dispatching.
- **gem/**: Handles the "Client" side. Responsible for socket connection, request serialization, and response parsing.
