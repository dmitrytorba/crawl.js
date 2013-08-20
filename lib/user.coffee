###
db.coffee
###

bcrypt    = require "bcrypt"
db        = require "./db"
mongoose  = require "mongoose"

SALT_WORK_FACTOR = 10

userSchema = mongoose.Schema(
  username:
    type:     String
    required: true
    unique:   true
  email:
    type:     String
    required: false
    unique:   true
  password:
    type:     String
    required: true
)

userSchema.pre "save", (next) ->
  user = this
  if !user.isModified "password"
    return next()
  bcrypt.genSalt SALT_WORK_FACTOR, (err, salt) ->
    if err
      return next(err)
    bcrypt.hash user.password, salt, (err, hash) ->
      if err
        return next(err)
      user.password = hash
      next()

userSchema.methods.comparePassword = (candidatePassword, cb) ->
  bcrypt.compare candidatePassword, this.password, (err, isMatch) ->
    if err
      return cb(err)
    cb null, isMatch

User = mongoose.model "User", userSchema

module.exports = User