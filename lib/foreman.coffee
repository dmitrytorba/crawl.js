events = require "events"
###
 Foreman
###
class Foreman extends events.EventEmitter
  port: 3000
  domain: "localhost"

  addWorker: ->
    spawn = require('child_process').spawn

    phantomjs = spawn('bin/phantomjs', ['--load-images=false', '--cookies-file=/dev/null', 'phantomjs/phantomWorker.coffee', "http://#{@domain}:#{@port}/phantom.html"]);

    phantomjs.stdout.on 'data', (data) ->
      console.log('stdout: ' + data)

    phantomjs.stderr.on 'data', (data) ->
      console.log('stderr: ' + data)

    phantomjs.on 'close', (code) ->
      console.log('child process exited with code ' + code)

module.exports = Foreman