# npm/AGENTS.md

This directory contains the **Node.js Server** implementation for Exots.

## Tech Stack
- **Language:** TypeScript
- **Package Manager:** `pnpm`
- **Linter/Formatter:** `biome`

## Key Commands
- **Install:** `pnpm install`
- **Build:** `pnpm run build`
- **Test:** `node --import tsx --test test/**/*.test.ts` (Native Node.js runner)
- **Format:** `pnpm run format`
- **Lint:** `pnpm run lint`
- **Check:** `pnpm run check`
- **Pack:** `npm pack` (Automatically includes root `LICENSE` and `README.md`)
- **Publish:** `npm publish`

## Code Style
- **Enforcement:** All code style is enforced by `biome`.
- **Indentation:** 2 spaces.
- **Semicolons:** NONE.
- **Imports:**
  - Built-ins: `import * as fs from 'fs'`
  - External: `import { ... } from 'pkg'`
- **Async:** Use `async/await`.

Refer to `src/server.ts` for existing patterns.
