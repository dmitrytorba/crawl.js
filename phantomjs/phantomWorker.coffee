fs      = require('fs')
sys     = require('system')
webpage = require('webpage')

if sys.args.length < 2
  console.log "Usage: phantomjs phantomWorker.coffee <PHANTOMJS_URL>"
  return

pushServerUrl = sys.args[1]

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
  #console.log "rendering #{url} to #{filename} ..."
  loadPage url, (page) ->
    return callback(null) unless page
    setTimeout ->
      fs.write filename, page.content
      callback(filename)
      page.release()
    , 1000

###
 Upload file using form
###
uploadFile = (file, form, callback) ->
  #console.log "uploading file #{file}..."
  page = webpage.create()
  html = "<html><body>"
  html += "<form action=\"#{form.action}\" method=\"post\" enctype=\"multipart/form-data\">"
  for n, v of form.fields
    html += "<input type=\"hidden\" name=\"#{n}\" value=\"#{v}\" >"
  html += "<input type=\"file\" name=\"file\" >"
  html += "</form></body></html>"
  page.content = html
  page.uploadFile("input[name=file]", file)
  page.onLoadFinished = (status) ->
    url = page.evaluate( -> location.href )
    if url is form.action
      page.onLoadFinished = null
      # console.log "s3 response: #{page.content}"
      loc = page.content.match(/<Location>(http[^<]+)<\/Location>/)
      if loc
        # console.log "file location: #{loc[1]}"
        callback loc[1]
      else
        callback null
      page.release()
  page.evaluate -> document.forms[0].submit()

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


extractUrlsFromPage = (page) ->
  foundURLs = page.evaluate ->
    result = []
    anchors = document.getElementsByTagName 'a'
    for anchor in anchors
      result.push anchor.href
    result
  foundURLs

###
 checks for snapshot markers ( like <meta name="fragment" content="!" /> )
###
checkPageForSnapshotMarkers = (page) ->
#  console.log "checking for page markers: #{page}"
  metaTags = page.evaluate ->
    result = []
    metaTags = document.getElementsByTagName 'meta'
    for metaTag in metaTags
      name = metaTag.getAttribute "name"
      content = metaTag.getAttribute "content"
      result.push name:name, content:content
    result
  for metaTag in metaTags
    if metaTag.name is "fragment" and metaTag.content is "!"
      return true

###
 Get URLs on a page
###
getURLs = (url, foundCallback, finishCallback) ->
  needsSnapshot = false
  loadPage url, (page) ->
    if page
      location = getLocation page
      foundURLs = extractUrlsFromPage page
      needsSnapshot = needsSnapshot || checkPageForSnapshotMarkers page
      if foundURLs and foundURLs.length isnt 0
        console.log "extracted #{foundURLs.length} URL"
        for foundURL in foundURLs
          foundCallback(foundURL)
      else
        console.log "found no URLs"
      page.close()
    else
      console.log "failed load: #{url}, #{page}"
    finishCallback(needsSnapshot)
    page.close()

###
 Connecting to socket.IO push server
###
connect = (callback) ->
  loadPage pushServerUrl, (page) ->
    if page
      console.log "connected to #{pushServerUrl}"
      conn = new Connection(page)
      callback(conn)
    else
      console.log "could NOT connect to #{pushServerUrl}"

###
 SocketIO server connection
###
class Connection
  constructor: (@page) ->
    page.onConsoleMessage = (msg) =>
      #console.log msg
      return unless msg.indexOf "dispatch:" is 0
      try
        request = JSON.parse(msg.substring(9))
        @onDispatch?(request)
      catch e

  onDispatch: null

  notify: (message) ->
    if message is "found"
      @page.evaluateAsync("function(){ notifyFound('#{arguments[1]}'); }")
    else if message is "needsSnapshot"
      @page.evaluateAsync("function(){ notifyNeedsSnapshot('#{arguments[1]}'); }")
    else if message is "complete"
      args = Array.prototype.slice.call(arguments, 1)
      @page.evaluateAsync("function(){ notifyComplete('#{args.join("','")}'); }")
    else
      @page.evaluateAsync("function(){ notifyFailure('#{message}'); }")


dispatchCount = 0

###
 init
###
connect (conn) ->
  return console.log("connection failure.") unless conn
  conn.onDispatch = (request) ->
    dispatchCount++
    if request.type is "urls"
      console.log "getting urls from #{request.url}"
      getURLs request.url, (foundURL) ->
          conn.notify "found", foundURL
        , (needsSnapshot) ->
          if needsSnapshot
            conn.notify "needsSnapshot", request.url
          else
            conn.notify "complete"
    else
        console.log "taking a snapshot of #{request.url}"
        if not request.form
          console.log "Snapshot Failed! #{request.url}"
          conn.notify("failure", request)
        else
          filename = Math.random().toString(36).substring(2)
          file = "/tmp/#{filename}.html"
          renderPage request.url, file, (file) ->
            uploadFile file, request.form, (snapshotUrl) ->
              if snapshotUrl
                console.log "Upload complete: #{snapshotUrl}"
                conn.notify("complete", request.url, snapshotUrl)
              else
                console.log "Upload Failed! #{request.url}"
                conn.notify("failure", request)
              fs.remove(file)


