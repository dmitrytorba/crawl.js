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
        if callback
            @redisClient.get "crawl-domain", (err, reply) ->
                callback(reply)

    ###
    the list of urls visted in this crawl
    ###
    addVisitedUrl: (url) ->
        @redisClient.hset "visited-url", url, "{}"

    isVisitedUrl: (url, callback) ->
        @redisClient.hexists "visited-url", url, (err, reply) ->
            callback(reply)

    resetVisitedDomains: ->
        @redisClient.del "visited-url"

    addJob: (job) ->
        @redisClient.lpush "jobs", JSON.stringify(job)

    getJob: (callback) ->
        @redisClient.rpop "jobs", (err, reply) ->
            callback(JSON.parse(reply))

    getJobCount: (callback) ->
        @redisClient.llen "jobs", (err, reply) ->
            callback(reply)

    clearJobs: ->
        @redisClient.del "jobs"

module.exports = new Brain()