###
app.coffee
###

events   = require "events"
express  = require "express"
crypto   = require "crypto"
socketio = require "socket.io"
http     = require "http"
URL      = require "url"
s3upload   = require "./s3upload"
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
exports.queue = queue

###
the crawl is limited to this domain
###
crawlDomain = null

###
the list of urls visted in this crawl
###
alreadyCrawled = null



###
setup crawl
###
initCrawl = (url) ->
  #reset crawl domain
  urlObj = URL.parse url
  console.log "crawl domain: #{urlObj.host}"
  crawlDomain = urlObj.host
  #reset crawl list
  alreadyCrawled = {}

###
parse url string 
###
parseURL = (urlStr) ->
  urlObj = URL.parse(urlStr)
  # console.log "#{urlObj.host}"
  urlObj

###
 url regexes to never visit 
###
blackList = [
  /.*ILinkListener.*/
]

###
check if url is on blacklists
###
isBlackListed = (url) ->
  for blockRegEx in blackList
    if url.match blockRegEx
      console.log "blocked: #{url}"
      return true
  return false

###
check if url is within our domain
###
isInsideCrawlDomain = (urlObj) ->
  if urlObj.host isnt crawlDomain
    console.log "$$$$$$$$$$$$$$$ wrong domain"
  urlObj.host is crawlDomain

###
check if url has been crawled this pass
###
isAlreadyCrawled = (url) ->
  if !alreadyCrawled[url]
    alreadyCrawled[url] = true
    false
  else
    console.log "$$$$$$$$$$$$ already crawled: #{url}"
    true

###
run checks on the url
###
okToCrawl = (url) ->
  # make sure valid url
  urlObj = parseURL url
  # check if on blacklist
  if !(isBlackListed url)
    # check if outside of crawl domain
    if isInsideCrawlDomain urlObj
      # check if already crawled
      if !(isAlreadyCrawled url)
        return true
  #failed, do not crawl
  return false

###
handler for url founds during crawl
###
processURL = (foundURL) ->
  console.log "<renderer> found #{foundURL}"
  if okToCrawl foundURL
    console.log "<requester> crawl"
    queue.enqueue
      url: foundURL
      type: "urls"
    channels.request.emit "image", foundURL


  #hash = sha1(response.url)
  #queue.enqueu
  #  url: response.url
  #  hash: hash
  #  form: s3upload.createForm(encodeURIComponent(response.url))


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
          console.log "<requester> render x#{url}"
          hash = sha1(url)
          queue.enqueue
            url: url
            type: "snapshot"
            hash: hash
            form: s3upload.createForm(encodeURIComponent(url))
        socket.on "crawl", (url) ->
          console.log "<requester> crawl"
          initCrawl url
          queue.enqueue
            url: url
            type: "urls"
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
          if response.snapshotUrl
            console.log "<renderer> notify #{response.snapshotUrl}"
            channels.request.emit "image", response.snapshotUrl
          queue.wait(renderer)
        socket.on "found", (response) ->
          processURL response.url
          queue.wait(renderer)
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
