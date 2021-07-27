var app = require("express")();
var http = require("http").createServer(app);
var io = require("socket.io")(http);

var port = process.env.PORT || 8080;

app.get("/", (req, res) => {
    res.send("<h1>Hello</h1>");
});

io.on("connection", (socket) => {
    console.log("User connected")

    socket.emit("message", "Hello")

    socket.on("disconnect", () => {
      console.log("User disconnected")
    })

    // Receives a message
    socket.on("message", (content) => {
      console.log("Got a message, now sending it on!", content)
      socket.broadcast.emit("message", content);
    })
});

http.listen(port, () => {
    console.log("Hi");
});
