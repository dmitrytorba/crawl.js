fs      = require('fs')
sys     = require('system')
webpage = require('webpage')

if sys.args.length < 2
  console.log "Usage: phantomjs screenshot.coffee <push-server-url> [screen-width] [screen-height] [image-width] [image-height] [wait]"
  return

pushServerUrl = sys.args[1]

renderingWait = Number(sys.args[6] || 1000)

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


parseURL = (url, location) ->
  if url[0] is '#'
    if (location.href.indexOf '#') is -1
      location.href + url
    else
      location.href.replace /#.*/, url
  else
    #TODO: other cases
    url

getLocation = (page) ->
    location =
      href: (page.evaluate ->
        window.location.href),
      hash: (page.evaluate ->
        window.location.hash)

extractUrlsFromPage = (page) ->
  result = []
  hrefs = page.content.match /href=['\"]([^'\"]*)['\"]/g
  for href in hrefs
    # remove the href= 
    url = href[6..-2]
    # check if empty
    if url
      # ignore css
      result.push url
  result

 

###
 Crawl a site
###
crawlPage = (url, found, finish) ->
  loadPage url, (page) ->
    if page
      location = getLocation page
      console.log "analyzing #{url}"
      foundURLs = extractUrlsFromPage page
      if foundURLs
        console.log "extracted #{foundURLs.length} URL"
        for foundURL in foundURLs
          if (foundURL.indexOf '#!') isnt -1
            foundURL = parseURL foundURL, location
            #found foundURL
          console.log "#{foundURL}"
          crawlPage foundURL, found
      else
        console.log "found no URLs"
    else
      console.log "bad url: #{url}"
    if finish
      finish()


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
        crawlPage(request.url,
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


