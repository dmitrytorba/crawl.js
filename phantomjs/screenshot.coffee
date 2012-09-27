fs      = require('fs')
sys     = require('system')
webpage = require('webpage')

if sys.args.length < 2
  console.log "Usage: phantomjs screenshot.coffee <push-server-url> [screen-width] [screen-height] [image-width] [image-height] [wait]"
  return

pushServerUrl = sys.args[1]

renderingWait = Number(sys.args[6] || 1000)

reusablePage = null

###
 Loading page
###
loadPage = (url, callback) ->
  page = webpage.create()
  page.onAlert = (msg) ->
    console.log msg
  page.onError = (msg, trace) ->
    console.log msg
    trace.forEach (item) -> console.log "  ", item.file, ":", item.line
  page.open url, (status) ->
    callback (if status is "success" then page else null)
  page


###
 Render and upload page image
###
renderPage = (url, filename, callback) ->
  console.log "rendering #{url} to #{filename} ..."
  loadPage url, (page) ->
    return callback(null) unless page
    setTimeout ->
      fs.write filename, page.content
      callback(filename)
    , 1000

###
 Upload file using form
###
uploadFile = (file, form, callback) ->
  console.log "uploading file #{file}..."
  page = webpage.create()
  html = "<html><body>"
  html += "<form action=\"#{form.action}\" method=\"post\" enctype=\"multipart/form-data\">"
  for n, v of form.fields
    html += "<input type=\"hidden\" name=\"#{n}\" value=\"#{v}\" >"
  html += "<input type=\"file\" name=\"file\" >"
  html += "</form></body></html>"
  page.content = html
  page.uploadFile("input[name=file]", file)
  page.evaluate -> document.forms[0].submit()
  page.onLoadFinished = (status) ->
    url = page.evaluate( -> location.href )
    if url is form.action
      page.onLoadFinished = null
      console.log "uploading done."
      loc = page.content.match(/<Location>(http[^<]+)<\/Location>/)
      if loc
        console.log "file location: #{loc[1]}"
        callback loc[1]
      else
        callback null
      page.release()

###
 Util function: check if string contains fragment
###
String.prototype.contains = (str) ->
  (this.indexOf str) isnt -1


###
 Util function: check if string starts with fragment
###
String.prototype.startsWith = (str) ->
  (this.indexOf str) is 0

###
 Check if url is a full url 
###
isCanonical = (url) ->
  url.startsWith('http')

###
 Convert href into canonical url 
###
parseURL = (url, page) ->
  location = getLocation page
  domainRoot = "#{location.protocol}//#{location.host}"

  if location.pathname.contains '/'
    path = location.pathname[0..location.pathname.lastIndexOf('/')]
  else
    path = ''

  currentLocation = "#{domainRoot}#{path}#{location.search}"

  if isCanonical(url)
    # case href="canoncial URL"
    url
  else if url.startsWith '#'
    # case: href="#tag'
    if (location.href.indexOf '#') is -1
      # append tag
      location.href + url
    else
      # replace existing tag
      location.href.replace /#.*/, url
  else if url.startsWith '/'
    # case href="path from root"
    domainRoot + url
  else
    # case href="path from current location"
    currentLocation + url

###
 Parse url to get its parts  
###
getLocation = (page) ->
    location =
      href: (page.evaluate ->
        window.location.href),
      host: (page.evaluate ->
        window.location.host),
      hostname: (page.evaluate ->
        window.location.hostname),
      pathname: (page.evaluate ->
        window.location.pathname),
      port: (page.evaluate ->
        window.location.port),
      protocol: (page.evaluate ->
        window.location.protocol)
      search: (page.evaluate ->
        window.location.search),
      hash: (page.evaluate ->
        window.location.hash)

###
 Find hrefs on the html page 
###
extractUrlsFromPage = (page) ->
  result = []
  hrefs = page.content.match /href=['\"]([^'\"]*)['\"]/g
  if hrefs
    for href in hrefs
      # remove the href= 
      url = href[6..-2]
      # check if empty
      if url
        # ignore css
        if url[-4..-1] isnt '.css'
          # make url canonical
          url = parseURL url, page
          # save it
          result.push url
    result

###
 url regexes to never visit 
###
blockList = [
  /.*ILinkListener.*/
]

###
 ignore url? 
###
isBlockListed = (url) ->
  for blockRegEx in blockList
    if url.match blockRegEx
      console.log "blocked: #{url}"
      return true

###
 Crawl a site
###
crawlSite = (url, found, finish) ->
  crawlPage url, found, finish, null, {}

###
 Crawl a page
###
crawlPage = (url, found, finish, currentHost, alreadyCrawled) ->
  if alreadyCrawled[url]
    console.log "skipping: #{url}"
    finish()
  else
    alreadyCrawled[url] = true
    loadPage url, ((page) ->
      if page
        location = getLocation page
        if !currentHost
          currentHost = location.host
        if location.host is currentHost
          console.log "********analyzing #{url}"
          foundURLs = extractUrlsFromPage page
          if foundURLs and foundURLs.length isnt 0
            console.log "extracted #{foundURLs.length} URL"
            
            i = foundURLs.length - 1
            helper = () ->
              if i isnt -1
                foundURL = foundURLs[i]
                console.log "Url# #{i+1} -> #{foundURL}"
                i--
                if isBlockListed foundURL
                  console.log "blocked!"
                  helper()
                else
                  helper()
                  #crawlPage foundURL, found, helper, currentHost, alreadyCrawled
                  found foundURL
              else
                finish()
            helper()
          else
            console.log "found no URLs"
            finish()
        else
          console.log "wrong host: #{location.host}"
          finish()
      else
        console.log "bad url: #{url}"
        finish()
    )


###
 Connecting to socket.IO push server
###
connect = (callback) ->
  loadPage pushServerUrl, (page) ->
    return conn(null) unless page
    console.log "connected to #{pushServerUrl}"
    conn = new Connection(page)
    callback(conn)

###
 SocketIO server connection
###
class Connection
  constructor: (@page) ->
    page.onConsoleMessage = (msg) =>
      console.log msg
      return unless msg.indexOf "render:" is 0
      try
        request = JSON.parse(msg.substring(7))
        @onRenderRequest?(request)
      catch e

  onRenderRequest: null

  notify: (message) ->
    if message is "found"
      @page.evaluate("function(){ notifyFound('#{arguments[1]}'); }")
    else if message is "complete"
      args = Array.prototype.slice.call(arguments, 1)
      @page.evaluate("function(){ notifyComplete('#{args.join("','")}'); }")
    else
      @page.evaluate("function(){ notifyFailure('#{args.join("','")}'); }")


###
 init
###
connect (conn) ->
  return console.log("connection failure.") unless conn
  conn.onRenderRequest = (request) ->
    if(request.crawl)
      console.log "onCrawl: #{request.url}"
      crawlSite(request.url,
          (url) -> (
            console.log "needs snapshot: #{url}"
            conn.notify("found", url)
          ),
          () -> (
            console.log "crawl complete"
            conn.notify("complete")
          )
        )
    else
        filename = Math.random().toString(36).substring(2)
        file = "/tmp/#{filename}.html"
        renderPage request.url, file, (file) ->
          console.log "file #{file}"
          uploadFile file, request.form, (snapshotUrl) ->
            if snapshotUrl
              conn.notify("complete", request.url, snapshotUrl)
            else
              conn.notify("failure",  request.url)
            fs.remove(file)


