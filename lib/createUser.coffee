###
createUser.coffee
###
User = require "./user"

if process.argv.length < 4
  console.log "Usage: node createUser.js username password"
  process.exit()

username = process.argv[2]
password = process.argv[3]

user = new User(
  username: username
  password: password
)

user.save (err) ->
  if err
    console.log err
  else
    console.log "user #{user.username} saved"
  process.exit()