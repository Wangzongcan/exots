# Exots

> **⚠️ Status: Work in Progress**
>
> This project is currently under active development. APIs and features are subject to change.

**Exots** (Exo-Typescript) is a high-performance Inter-Process Communication (IPC) bridge designed to allow Ruby applications to seamlessly invoke functions written in TypeScript.

It utilizes **JSON-RPC 2.0** over **HTTP** running on **Unix Domain Sockets (UDS)**. This approach ensures high performance and security by avoiding local TCP ports and leveraging file-system-level access control.

## Architecture

The system consists of two main components communicating via a Unix Domain Socket file:

1.  **Server (TypeScript/Node.js)**: Imports the `exots` npm package. It wraps a set of TypeScript functions and exposes them via an HTTP server listening exclusively on a `.sock` file.
2.  **Client (Ruby)**: Imports the `exots` gem. It connects to the `.sock` file and proxies Ruby method calls to the remote TypeScript functions using JSON-RPC.

## Components

### NPM Package
- **Role**: RPC Server
- **Transport**: HTTP over Unix Domain Socket
- **Protocol**: JSON-RPC 2.0
- **Configuration**: Accepts a map of functions and a path to a socket file.

### Ruby Gem
- **Role**: RPC Client
- **Transport**: HTTP over Unix Domain Socket
- **Features**:
    - Automatic method proxying via `method_missing`.
    - Converts Ruby keyword arguments/positional arguments to JSON-RPC params.
    - Maps JSON-RPC errors to Ruby exceptions.

## Usage Example

### TypeScript Side
```typescript
import { Exots } from 'exots';

const rpc = new Exots({
  // Define functions to expose
  add: (a: number, b: number) => a + b,
  renderComponent: async (props: any) => {
    // Complex logic (e.g., SSR)
    return "<html>...</html>";
  }
});

// Listen on a Unix Socket file
rpc.listen('/tmp/exots.sock');
```

### Ruby Side
```ruby
require 'exots'

# Connect to the socket
client = Exots::Client.new('/tmp/exots.sock')

# Call functions transparently
result = client.add(1, 2)
# => 3

html = client.render_component({ title: "Hello" })
# => "<html>...</html>"
```
