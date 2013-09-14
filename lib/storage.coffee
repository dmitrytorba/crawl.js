###
storage.coffee
###

db        = require "./db"
mongoose  = require "mongoose"

storageSchema = mongoose.Schema(
  name:
    type:     String
    required: true
    unique:   true
  type:
    type:     String
    required: true
  location:
    type:     String
    required: true
  path:
    type:     String
    required: true
  key:
    type:     String
    required: true
  secret:
    type:     String
    required: true
  format:
    type:     String
    required: true
)

Storage = mongoose.model "Storage", storageSchema

module.exports = Storage