events = require "events"
###
 Foreman
###
class Foreman extends events.EventEmitter
  addWorker: ->
    exec = require('child_process').exec

    spawn = require('child_process').spawn
    phantomjs  = spawn('phantomjs-1.8.2-macosx/phantomjs', ['--load-images=false', '--cookies-file=/dev/null', 'phantomjs/phantomWorker.coffee', "http://localhost:#{port}/phantom.html"]);

    phantomjs.stdout.on 'data', (data) ->
      console.log('stdout: ' + data)

    phantomjs.stderr.on 'data', (data) ->
      console.log('stderr: ' + data)

    phantomjs.on 'close', (code) ->
      console.log('child process exited with code ' + code)

module.exports = Foreman