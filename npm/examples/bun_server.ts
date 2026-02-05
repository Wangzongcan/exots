import { Server } from "../dist"

const server = new Server({
  ping: () => "pong",
  echo: ({ msg }: { msg: string }) => msg,
  add: ({ a, b }: { a: number; b: number }) => a + b,
  sum: (a: number, b: number) => a + b,
  error_method: () => {
    throw new Error("Something went wrong")
  },
  slow_method: async () => {
    return new Promise((resolve) => setTimeout(() => resolve("done"), 100))
  },
})

server.run(process.argv)
