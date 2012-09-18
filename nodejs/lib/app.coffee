###
app.coffee
###

events   = require "events"
express  = require "express"
crypto   = require "crypto"
socketio = require "socket.io"
http     = require "http"
WorkerQueue = require "./queue"

app = module.exports = express()
server = http.createServer(app)

###
Express server configure
###
app.configure ->
  app.set "views", __dirname + "/../views"
  app.set "view engine", "ejs"
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router
  app.use express.static(__dirname + "/../public")

app.configure "development", ->
  app.use express.errorHandler(
    dumpExceptions: true
    showStack: true 
  )

app.configure "production", ->
  app.use express.errorHandler()


###
SHA1 Hash Utility Function
###
sha1 = (str) ->
  crypto.createHash('sha1').update(str).digest('hex')


###
Worker Queue
###
queue = new WorkerQueue()


###
Socket IO Channels
###
io = socketio.listen(server)

io.configure ->
  io.set "transports", ["xhr-polling"] 
  io.set "polling duration", 10 

channels =
  request:
    io.of("/request")
      .on "connection", (socket) ->
        console.log "<requester> connect"
        socket.on "render", (url) ->
          console.log "<requester> render #{url}"
          hash = sha1(url)
          queue.enqueue
            url: url
            hash: hash
        socket.on "disconnect", ->
          console.log "<requester> disconnect"

  render:
    io.of("/render")
      .on "connection", (socket) ->
        console.log "<renderer> connect"
        renderer = new events.EventEmitter()
        renderer.on "dispatch", (req) -> socket.emit "render", req
        queue.wait(renderer)
        socket.on "complete", (response) ->
          console.log "<renderer> notify #{response.imageUrl}"
          channels.request.emit "image", response.html
        socket.on "fail", ->
          queue.wait(renderer)
        socket.on "disconnect", ->
          console.log "<renderer> disconnect"
          queue.remove(renderer)


###
Start server
###
port = process.env.PORT ? 3000
server.listen port
console.log "Express server listening on port %d in %s mode", port, app.settings.env
