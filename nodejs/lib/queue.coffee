events = require "events"
###
 Worker Queue
###
class WorkerQueue extends events.EventEmitter
  maxWorkers: 100
  maxRequests: 2500

  constructor: ->
    @_requests = []
    @_workers = []

  wait: (worker) ->
    console.log "<queue> wait"
    request = @_requests.pop()
    @emit "jobs", @_requests.length
    if request
      worker.emit "dispatch", request
    else if @maxWorkers > @_workers.length
      console.log "bad request encountered"
      @_workers.push(worker)
    else
      console.log "Max Workers exeeded"
  
  remove: (worker) ->
    console.log "<queue> remove"
    @_workers = (w for w in @_workers when w isnt worker)

  enqueue: (request, topPriority) ->
    console.log "<queue> enqueue"
    worker = @_workers.shift()
    if worker
      worker.emit "dispatch", request
    else if @maxRequests > @_requests.length
      @_requests.push(request)
      @emit "jobs", @_requests.length
    else
      console.log "Request Limit Exceeded"

  kill: () ->
    @_requests = []
    @emit "jobs", @_requests.length

  getJobCount: () ->
    @_requests.length



module.exports = WorkerQueue
