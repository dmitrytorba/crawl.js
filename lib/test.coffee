###
test.coffee
###

app = require("./app")
queue = app.queue

console.log "test"
queue.enqueue
  url: "localhost"
  crawl: true


#process.exit()
