events = require "events"
###
 Worker Queue
###
class WorkerQueue extends events.EventEmitter
  maxWorkers: 100
  maxRequests: 250

  constructor: ->
    @_requests = []
    @_workers = []

  wait: (worker) ->
    request = @_requests.shift()
    if request
      console.log "items in queue: #{@_workers.length}"
      worker.emit "dispatch", request
    else if @maxWorkers > @_workers.length
      @_workers.push(worker)
    else
      console.log "Max Workers exeeded"
  
  remove: (worker) ->
    @_workers = (w for w in @_workers when w isnt worker)

  enqueue: (request) ->
    worker = @_workers.shift()
    if worker
      worker.emit "dispatch", request
    else if @maxRequests > @_requests.length
      @_requests.push(request)
    else
      console.log "Request Limit Exceeded"


module.exports = WorkerQueue
