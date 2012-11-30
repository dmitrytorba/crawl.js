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
    dumpExceptions: false
    showStack: false
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

queue.on "jobs", (jobsCount) ->
  console.log "jobCount: #{jobsCount}"
  sockets.ui.emit "jobs", jobsCount

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
    #console.log "$$$$$$$$$$$$ already crawled: #{url}"
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
parts of the url to replace-rewrite
(useful if you have a session parameter)
###
urlReplace = [
  {
    pattern: /\?\d{8,10}&/,
    value: '?'
  },
  {
    pattern: /\?\d{8,10}#/,
    value: '#'
  },
  {
    pattern: /#$/,
    value: ''
  }
]

###
rewrite URL according to rules
###
rewriteURL = (url) ->
  for urlReplacement in urlReplace
    url = url.replace urlReplacement.pattern, urlReplacement.value
  url


###
 url regexes to snapshot 
###
snapshotList = [
  /.*#!.*/
]

###
check if url needs snapshot 
###
needsSnapshot = (url) ->
  for snapshotRegEx in snapshotList
    if url.match snapshotRegEx
      return true
  return false

###
handler for url founds during crawl
###
processURL = (foundURL) ->
  # clean up the URL
  foundURL = rewriteURL foundURL
  # check if OK to continue crawl on this URL
  if okToCrawl foundURL
    # schedule a worker to crawl this URL
    queue.enqueue
      url: foundURL
      type: "urls"
    # let the UI know a valid URL was found
    #sockets.ui.emit "foundURL", foundURL
    if needsSnapshot foundURL
      # sched a job to take the snapshot
      # sockets.ui.emit "foundURL", foundURL
      hash = sha1(foundURL)
      queue.enqueue
        url: foundURL
        hash: hash
        form: s3upload.createForm(encodeURIComponent(foundURL))


###
Socket IO Channels
###
io = socketio.listen(server)

io.configure ->
  io.set "transports", ["xhr-polling"]
  io.set "polling duration", 10

sockets =
  ui:
    io.of("/ui")
      .on "connection", (socket) ->
        console.log "<ui> connected"
        # TODO
        socket.on "render", (url) ->
          console.log "<ui> render x#{url}"
          hash = sha1(url)
          queue.enqueue
            url: url
            type: "snapshot"
            hash: hash
            form: s3upload.createForm(encodeURIComponent(url))
        # start a new crawl
        socket.on "crawl", (url) ->
          console.log "<ui> crawl requested"
          initCrawl url
          queue.enqueue
            url: url
            type: "urls"
        socket.on "disconnect", ->
          console.log "<ui> disconnected"

  render:
    io.of("/phantom")
      .on "connection", (socket) ->
        console.log "<phantom> connected"
        phantomWorker = new events.EventEmitter()
        # go do this work 
        phantomWorker.on "dispatch", (req) -> 
          socket.emit "dispatch", req
        # wait for work
        queue.wait(phantomWorker)
        # TODO
        socket.on "complete", (response) ->
          if response.snapshotUrl
            console.log "<phantom> notify #{response.snapshotUrl}"
            sockets.ui.emit "image", response.snapshotUrl
          queue.wait(phantomWorker)
        # a URL was found during the crawl
        socket.on "found", (response) ->
          processURL response.url
        socket.on "fail", ->
          queue.wait(phantomWorker)
        socket.on "disconnect", ->
          console.log "<phantom> disconnect"
          queue.remove(phantomWorker)


###
Start server
###
port = process.env.PORT ? 3000
server.listen port
console.log "Express server listening on port %d in %s mode", port, app.settings.env
