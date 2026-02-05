# Exots

> **⚠️ Status: Work in Progress**
>
> This project is currently under active development. APIs and features are subject to change.

**Exots** (Exo-Typescript) is a high-performance Inter-Process Communication (IPC) bridge designed to allow Ruby applications to seamlessly invoke functions written in TypeScript/JavaScript.

It acts as a **process manager** that spawns a Node.js (or Bun/Deno) runtime and communicates via **JSON-RPC 2.0** over **HTTP** on **Unix Domain Sockets (UDS)**. This approach ensures high performance and security by avoiding local TCP ports and leveraging file-system-level access control.

## Architecture

The system operates on a Host/Plugin model:

1.  **Host (Ruby)**: The `exots` gem manages the lifecycle of the JavaScript process. It creates a temporary communication socket and injects its path into the child process.
2.  **Plugin (TypeScript/Node.js)**: The `exots` npm package wraps your functions and exposes them via an HTTP server listening on the injected socket path.

## Components

### NPM Package (`exots`)
-   **Role**: RPC Server
-   **Transport**: HTTP over Unix Domain Socket
-   **Protocol**: JSON-RPC 2.0
-   **Configuration**: Accepts a map of functions and listens on a socket path provided via environment variables.

### Ruby Gem (`exots`)
-   **Role**: Process Manager & RPC Client
-   **Features**:
    -   Spawns and manages the Node.js/Bun process.
    -   Automatic socket path generation and handshake.
    -   Zero-dependency HTTP client over Unix Sockets.
    -   Maps JSON-RPC errors to Ruby exceptions.

## Usage Example

### 1. TypeScript Side (`plugin.js`)
Create a script that exports your functions.

```javascript
import { Server } from 'exots'

// 1. Initialize the server with exposed functions
const server = new Server({
  add: ({ a, b }) => a + b,
  render: async ({ title }) => {
    // Perform complex operations, e.g., SSR
    return `<div>${title}</div>`
  }
})

// 2. Start listening using injected environment variables
server.listen({
  socket: process.env.EXOTS_SOCKET,
  pid: process.env.EXOTS_PID
}).then(() => {
  console.log('RPC Server ready')
})
```

### 2. Ruby Side
Use the client to spawn the process and call functions.

```ruby
require 'exots'

# 1. Initialize the client
client = Exots::Client.new(
  script_path: "plugin.js",
  socket_path: Rails.root.join("tmp/sockets/exots.sock")
)

begin
  # 2. Start the process and connect
  context = client.start

  # 3. Call functions transparently
  sum = context.call("add", a: 5, b: 3)
  puts "Sum: #{sum}" 
  # => Sum: 8

  html = context.call("render", title: "Hello World")
  puts "HTML: #{html}"
  # => HTML: <div>Hello World</div>

ensure
  # 4. Clean shutdown
  client.stop
end
```
