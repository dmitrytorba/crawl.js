events    = require "events"
redis     = require "redis"

###
 Brain
###
class Brain extends events.EventEmitter
    constructor: ->
        @redisClient = redis.createClient()

    ###
    the crawl is limited to this domain
    ###
    setCrawlDomain: (domain) ->
        @redisClient.set "crawl-domain", domain

    getCrawlDomain: (callback)->
        @redisClient.get "crawl-domain", (err, reply) ->
            callback(reply)

    ###
    the list of urls visted in this crawl
    ###
    addVisitedUrl: (url) ->
        @redisClient.hset "visited-url", url, "{}"

    isVisitedUrl: (url, callback) ->
        @redisClient.hexists url, (err, reply) ->
            callback(reply)

    resetVisitedDomains: ->
        @redisClient.del "visited-url"

module.exports = new Brain()