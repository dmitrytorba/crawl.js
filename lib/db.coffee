###
db.coffee
###

mongoose  = require "mongoose"


###
MongoDB configure
###
mongoose.connect "mongodb://localhost/test"
db = mongoose.connection
db.on("error", console.error.bind(console, "connection error: "))
db.on "open", () ->
  console.log "connected to mongodb"


module.exports = db