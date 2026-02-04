import * as fs from "node:fs"
import * as http from "node:http"
import * as net from "node:net"
import { JSONRPCServer } from "json-rpc-2.0"

export interface ListenOptions {
  socket: string
  pid?: string
}

export class Server {
  server: http.Server
  rpc: JSONRPCServer
  isClosing: boolean = false
  socketPath?: string
  pidFile?: string

  constructor(methods: Record<string, Function>) {
    this.rpc = new JSONRPCServer()
    Object.entries(methods).forEach(([name, fn]) => {
      this.rpc.addMethod(name, (params) => fn(params))
    })

    this.server = http.createServer((req, res) => this.handle(req, res))

    const stop = () => this.stop()
    process.on("SIGINT", stop)
    process.on("SIGTERM", stop)
  }

  async listen(opts: ListenOptions) {
    this.socketPath = opts.socket
    this.pidFile = opts.pid

    if (fs.existsSync(this.socketPath)) {
      if (await this.isSocketActive(this.socketPath))
        throw new Error(`Socket ${this.socketPath} in use`)
      fs.unlinkSync(this.socketPath)
    }

    return new Promise<void>((resolve, reject) => {
      this.server.listen(this.socketPath, () => {
        if (this.pidFile) {
          try {
            fs.writeFileSync(this.pidFile, process.pid.toString())
          } catch {
            /* ignore */
          }
        }
        resolve()
      })
      this.server.on("error", reject)
    })
  }

  stop() {
    if (this.isClosing) return
    this.isClosing = true

    this.server.close(() => {
      if (this.socketPath && fs.existsSync(this.socketPath)) {
        try {
          fs.unlinkSync(this.socketPath)
        } catch {
          /* ignore */
        }
      }
      if (this.pidFile && fs.existsSync(this.pidFile)) {
        try {
          fs.unlinkSync(this.pidFile)
        } catch {
          /* ignore */
        }
      }
      process.exit(0)
    })
  }

  handle(req: http.IncomingMessage, res: http.ServerResponse) {
    if (req.method !== "POST") {
      res.statusCode = 405
      res.end()
      return
    }

    const chunks: Buffer[] = []
    req.on("data", (c) => chunks.push(c))
    req.on("end", async () => {
      try {
        const body = JSON.parse(Buffer.concat(chunks).toString())
        const result = await this.rpc.receive(body)
        if (result) {
          res.setHeader("Content-Type", "application/json")
          res.end(JSON.stringify(result))
        } else {
          res.statusCode = 204
          res.end()
        }
      } catch {
        res.statusCode = 400
        res.end()
      }
    })
  }

  isSocketActive(path: string) {
    return new Promise((resolve) => {
      const client = net
        .createConnection(path)
        .on("connect", () => {
          client.end()
          resolve(true)
        })
        .on("error", () => resolve(false))
    })
  }
}
