events = require "events"
brain     = require "./brain"

###
 Worker Queue
###
class WorkerQueue extends events.EventEmitter
  maxWorkers: 100

  constructor: ->
    @_workers = []
    @phantomWorkers = []

  wait: (worker) ->
    console.log "<queue> wait"
    queue = @
    brain.getJob (request) ->
        brain.getJobCount (jobCount) ->
            queue.emit "jobs", jobCount
        if request
          worker.emit "dispatch", request
        else
          # wait for request
          queue._workers.push(worker)

  remove: (worker) ->
    console.log "<queue> remove"
    @_workers = (w for w in @_workers when w isnt worker)

  enqueue: (request, topPriority) ->
    console.log "<queue> enqueue #{request.url}"
    queue = @
    worker = @_workers.shift()
    if worker
      console.log "<queue> dispatching #{request.url}"
      worker.emit "dispatch", request
    else
      brain.addJob(request)
      brain.getJobCount (jobCount) ->
        queue.emit "jobs", jobCount

  addWorker: (worker) ->
    @phantomWorkers.push(worker)

  kill: () ->
    @_workers = @phantomWorkers
    queue = @
    brain.getJobCount (jobCount) ->
      queue.emit "jobs", jobCount

  getJobCount: (callback) ->
    brain.getJobCount (jobCount) ->
      callback(jobCount)



module.exports = WorkerQueue
