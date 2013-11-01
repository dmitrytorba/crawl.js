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
    @phantomWorkers = []

  wait: (worker) ->
    console.log "<queue> wait"
    request = @_requests.shift()
    @emit "jobs", @_requests.length
    if request
      worker.emit "dispatch", request
    else if @maxWorkers > @_workers.length
      # wait for request
      @_workers.push(worker)
    else
      console.log "Max Workers exeeded"
  
  remove: (worker) ->
    console.log "<queue> remove"
    @_workers = (w for w in @_workers when w isnt worker)

  enqueue: (request, topPriority) ->
    console.log "<queue> enqueue #{request.url}"
    worker = @_workers.shift()
    if worker
      console.log "<queue> dispatching #{request.url}"
      worker.emit "dispatch", request
    else if @maxRequests > @_requests.length
      @_requests.push(request)
      @emit "jobs", @_requests.length
    else
      console.log "Request Limit Exceeded"

  addWorker: (worker) ->
    @phantomWorkers.push(worker)

  kill: () ->
    @_requests = []
    @_workers = @phantomWorkers
    @emit "jobs", @_requests.length

  getJobCount: () ->
    @_requests.length



module.exports = WorkerQueue
