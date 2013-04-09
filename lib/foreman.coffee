events   = require "events"
util     = require "util"
spawn    = require('child_process').spawn
###
 Foreman
###
class Foreman extends events.EventEmitter
  port: 3000
  domain: "localhost"
  workers: []

  setPort: (port) ->
    @port = port

  addWorker: ->
    phantomjs = spawn('bin/phantomjs', ['--load-images=false', '--cookies-file=/dev/null', 'phantomjs/phantomWorker.coffee', "http://#{@domain}:#{@port}/phantom.html"]);

    phantomjs.id = @workers.length

    @workers[phantomjs.id] = phantomjs

    phantomjs.stdout.on 'data', (data) ->
      util.log("[phantom-#{phantomjs.id}]: #{data}")

    phantomjs.stderr.on 'data', (data) ->
      util.log("[phantom-#{phantomjs.id}]: #{data}")

    phantomjs.on 'close', (code) ->
      util.log("[phantom-#{phantomjs.id}]: exited with code #{code}")

  removeWorker: () ->
    if @workers.length
      phantomjs = @workers.pop()
      phantomjs.kill "SIGHUP"


module.exports = Foreman