assert    = require "assert"
should    = require "should"
s3upload  = require "../lib/s3upload"

describe "s3upload", () ->

  describe "test", () ->
    it "needs to have valid s3 id + key", () ->
      should.exist process.env.AWS_ACCESS_KEY_ID
      should.exist process.env.AWS_SECRET_ACCESS_KEY

  describe "in general", () ->
    it "needs access to S3", (done) ->
      s3client = s3upload.getS3Client()
      should.exist s3client

      buffer = new Buffer 'a string of data'
      headers = 'Content-Type': 'text/plain'

      s3client.putBuffer buffer, 'test/test.txt', headers, (err, res) ->
        res.statusCode.should.equal 200
        done()

  describe "garbage collection", () ->
    before (done) ->
      s3client = s3upload.getS3Client()
      buffer = new Buffer 'a string of data'
      headers = 'Content-Type': 'text/plain'

      s3client.putBuffer buffer, 'test/one.txt', headers, (err, res) ->
        done()

    it "should be able to clear a folder", (done) ->
      s3upload.clearS3Folder "test", () ->
        s3client = s3upload.getS3Client()
        s3client.list "prefix": "test/", (err, data) ->
          data.Contents.length.should.equal 0
          done()
