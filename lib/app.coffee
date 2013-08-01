###
app.coffee
###

events        = require "events"
express       = require "express"
crypto        = require "crypto"
socketio      = require "socket.io"
http          = require "http"
util          = require "util"
passport      = require "passport"
LocalStategy  = (require "passport-local").Strategy
User          = require "./user"
s3upload      = require "./s3upload"
WorkerQueue   = require "./queue"
Crawler       = require "./crawler"
Foreman       = require "./foreman"

port = process.env.PORT ? 3000

app = module.exports = express()
server = http.createServer(app)

###
Passport
###
passport.serializeUser (user, done) ->
  done null, user.id

passport.deserializeUser (id, done) ->
  User.findById id, (err, user) ->
    done err, user

passport.use new LocalStategy (username, password, done) ->
  User.findOne
    username: username,
      (err, user) ->
        if err
          return done err
        if not user
          return done null, false, message: "unknown user: #{username}"
        user.comparePassword password, (err, isMatch) ->
          if err
            return done err
          if isMatch
            return done null, user
          else
            return done null, false, message: "invalid password"


###
Express server configure
###
app.configure ->
  app.set "views", __dirname + "/../views"
  app.set "view engine", "ejs"
  app.engine "ejs", require "ejs-locals"
  app.use express.cookieParser()
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use express.session secret: "keyboard cat"
  app.use passport.initialize()
  app.use passport.session()
  app.use app.router
  app.use express.static(__dirname + "/../public")

app.configure "development", ->
  app.use express.errorHandler(
    dumpExceptions: false
    showStack: false
  )

app.configure "production", ->
  app.use express.errorHandler()


ensureAuthenticated = (req, res, next) ->
  if req.isAuthenticated()
    return next()
  res.redirect "/login"

app.get "/", (req, res) ->
  console.log "found: #{req.user}"
  res.render "index", user: req.user

app.get "/account", (req, res) ->
  res.render "account", user: req.user

app.get "/login", (req, res) ->
  res.render "login", user: req.user

app.post "/login", (req, res, next) ->
  passport.authenticate("local", (err, user, info) ->
    if err
      return next err
    if not user
      return res.redirect 'login'
    req.login user, (err) ->
      if err then return next err
      return res.redirect "/"
  ) req, res, next

app.get "/logout", (req,res) ->
  req.logout()
  res.redirect "/"

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
  #console.log "jobCount: #{jobsCount}"
  sockets.ui.emit "jobs", jobsCount

numberOfPhantoms = 0
jobsCompleted = 0

###
Crawler
###
crawler = new Crawler()
crawler.setQueue queue

###
PhantomJS process manager
###
foreman = new Foreman()
foreman.setPort port

###
Socket IO Channels
###
io = socketio.listen(server)

io.configure 'development', ->
  io.set 'log level', 0

sockets =
  ui:
    io.of("/ui")
      .on "connection", (socket) ->
        util.log "<ui> connected"
        sockets.ui.emit "jobs", queue.getJobCount()
        sockets.ui.emit "phantomCount", numberOfPhantoms
        sockets.ui.emit "jobsCompleted", jobsCompleted

        socket.on "render", (url) ->
          #console.log "<ui> render #{url}"
          hash = sha1(url)
          filename = hash
          if crawler.filenameFormat is "URLENCODE"
            filename = encodeURIComponent(url)
          queue.enqueue
            url: url
            type: "snapshot"
            hash: hash
            form: s3upload.createForm(filename)
        # start a new crawl
        socket.on "crawl", (config) ->
          #console.log "<ui> crawl requested"
          crawler.initCrawl config
          queue.enqueue
            url: config.url
            type: "urls"
        socket.on "addWorker", ->
          #console.log "<ui> addWorker"
          foreman.addWorker()
        socket.on "removeWorker", ->
          #console.log "<ui> removeWorker"
          foreman.removeWorker()
        socket.on "kill", ->
          #console.log "<ui> kill requested"
          crawler.killCrawl()
          queue.kill()
        socket.on "disconnect", ->
          util.log "<ui> disconnected"

  render:
    io.of("/phantom")
      .on "connection", (socket) ->
        #util.log "<phantom> connected"
        numberOfPhantoms++
        sockets.ui.emit "phantomCount", numberOfPhantoms
        phantomWorker = new events.EventEmitter()
        queue.addWorker phantomWorker
        # go do this work 
        phantomWorker.on "dispatch", (req) ->
          socket.emit "dispatch", req
        # wait for work
        queue.wait(phantomWorker)
        # TODO
        socket.on "complete", (response) ->
          #console.log "<phantom> complete"
          if response.snapshotUrl
            sockets.ui.emit "snapshot", {
              snapshotUrl: response.snapshotUrl
              originalUrl: response.url
            }
          queue.wait(phantomWorker)
          jobsCompleted++
          sockets.ui.emit "jobsCompleted", jobsCompleted
        socket.on "needsSnapshot", (response) ->
          if response.url
            # take a snapshot
            hash = sha1(response.url + "#!")
            filename = hash
            if crawler.filenameFormat is "URLENCODE"
              filename = encodeURIComponent(response.url + "#!")
            queue.enqueue
              url: response.url
              hash: hash
              form: s3upload.createForm(filename)
          queue.wait(phantomWorker)
          jobsCompleted++
          sockets.ui.emit "jobsCompleted", jobsCompleted
        # a URL was found during the crawl
        socket.on "found", (response) ->
          crawler.processURL response.url
        socket.on "failure", (request) ->
          util.log "<phantom> failed, will try later"
          queue.wait(phantomWorker)
          queue.enqueue(request)
        socket.on "disconnect", ->
          util.log "<phantom> disconnect"
          numberOfPhantoms--
          sockets.ui.emit "phantomCount", numberOfPhantoms
          queue.remove(phantomWorker)

###
Start server
###
server.listen port
util.log "Express server listening on port #{port} in #{app.settings.env} mode"