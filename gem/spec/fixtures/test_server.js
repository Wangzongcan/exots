const { Server } = require("../../../npm/dist");

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

server.listen({
  socket: process.env.EXOTS_SOCKET,
  pid: process.env.EXOTS_PID
}).catch(err => {
  console.error(err);
  process.exit(1);
});
