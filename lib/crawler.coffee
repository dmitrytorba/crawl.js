events    = require "events"
URL       = require "url"
crypto    = require "crypto"
s3upload  = require "./s3upload"
Storage   = require "./storage"
###
 Crawler
###
class Crawler extends events.EventEmitter
  ###
  the crawl is limited to this domain
  ###
  crawlDomain = null

  ###
  the list of urls visted in this crawl
  ###
  alreadyCrawled = null

  ###
  how to name the file in s3 (HASH|URLENCODE)
  ###
  filenameFormat = "HASH"

  ###
  delete files in s3 before crawl? (APPEND|REPLACE)
  ###
  bucketStrategy = "APPEND"

  constructor: (config) ->
    #reset crawl domain
    crawlDomain = ""
    #reset crawl list
    alreadyCrawled = {}
    if config
      @initCrawl(config)

  setQueue: (queue) ->
    @queue = queue

  ###
  SHA1 Hash Utility Function
  ###
  sha1: (str) ->
    crypto.createHash('sha1').update(str).digest('hex')


  ###
  setup crawl
  ###
  initCrawl: (config) ->
    #reset crawl domain
    urlObj = URL.parse config.url
    crawlDomain = urlObj.host
    path = config.path || crawlDomain
    bucketStrategy = config.bucketStrategy || bucketStrategy

    Storage.findOne(
      name: config.storage,
      (err, storage) ->
        s3upload.setBucket storage.location
        s3upload.setId storage.key
        s3upload.setPasswd storage.secret
        s3upload.setPath storage.path
        filenameFormat = storage.format || filenameFormat
    )

    if bucketStrategy is "REPLACE"
      s3upload.clearS3Folder path

  killCrawl: () ->
    #reset crawl domain
    crawlDomain = ""
    #reset crawl list
    alreadyCrawled = {}

  ###
  parse url string
  ###
  parseURL: (urlStr) ->
    urlObj = URL.parse(urlStr)
    # console.log "#{urlObj.host}"
    urlObj

  ###
   url regexes to never visit
    @todo move to config
  ###
  blackList: [
    /.*ILinkListener.*/,
    /.*appdirect.com\/#.*/
  ]

  ###
  check if url is on blacklists
  ###
  isBlackListed: (url) ->
    for blockRegEx in @blackList
      if url.match blockRegEx
        return true
    return false

  ###
  check if url is within our domain
  ###
  isInsideCrawlDomain: (urlObj) ->
    #  if urlObj.host isnt crawlDomain
    #    console.log "$$$$$$$$$$$$$$$ wrong domain"
    urlObj.host is crawlDomain

  ###
  check if url has been crawled this pass
  ###
  isAlreadyCrawled: (url) ->
    if !alreadyCrawled[url]
      alreadyCrawled[url] = true
      false
    else
      #console.log "$$$$$$$$$$$$ already crawled: #{url}"
      true

  ###
  run checks on the url
  ###
  okToCrawl: (url) ->
    # make sure valid url
    urlObj = @parseURL url
    # check if on blacklist
    if !(@isBlackListed url)
      # check if outside of crawl domain
      if @isInsideCrawlDomain urlObj
        # check if already crawled
        if !(@isAlreadyCrawled url)
          return true
    #failed, do not crawl
    return false

  ###
  parts of the url to replace-rewrite
  (useful if you have a session parameter)
  ###
  urlReplace: [
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
  rewriteURL: (url) ->
    for urlReplacement in @urlReplace
      url = url.replace urlReplacement.pattern, urlReplacement.value
    url


  ###
   url regexes to snapshot
    @todo move to config
  ###
  snapshotList: [
    /.*#!.*/
  ]

  ###
  check if url needs snapshot
  ###
  needsSnapshot: (url) ->
    for snapshotRegEx in @snapshotList
      if url.match snapshotRegEx
        return true
    return false

  ###
  handler for url founds during crawl
  ###
  processURL: (foundURL) ->
    # clean up the URL
    foundURL = @rewriteURL foundURL
    # check if OK to continue crawl on this URL
    console.log "processing: #{foundURL}"
    if @okToCrawl foundURL
      # schedule a worker to crawl this URL
      @queue.enqueue
        url: foundURL
        type: "urls"
      # let the UI know a valid URL was found
      if @needsSnapshot foundURL
        console.log "$$$$$$$ needsSnapshot=true #{foundURL}"
        # sched a job to take the snapshot
        hash = @sha1(foundURL)
        filename = hash
        if filenameFormat is "URLENCODE"
          filename = encodeURIComponent(foundURL)
        @queue.enqueue
          url: foundURL
          hash: hash
          form: s3upload.createForm(filename)

module.exports = Crawler