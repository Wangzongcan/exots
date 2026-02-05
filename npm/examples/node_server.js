const { Server } = require("../dist")

const server = new Server({
  ping: () => "pong",
  echo: ({ msg }) => msg,
  add: ({ a, b }) => a + b,
  error_method: () => {
    throw new Error("Something went wrong");
  },
  slow_method: async () => {
    return new Promise(resolve => setTimeout(() => resolve("done"), 100));
  }
});

server.run(process.argv);
 