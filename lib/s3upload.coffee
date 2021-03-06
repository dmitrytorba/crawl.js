crypto = require "crypto"
knox = require "knox"

config =
  aws:
    accessKeyId: process.env.AWS_ACCESS_KEY_ID
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
  upload:
    bucketName: process.env.UPLOAD_BUCKET_NAME
    path: 'seo/'
    expiration: 360

toISO8601 = (d) ->
  pad2 = (n) -> (if n < 10 then '0' else '') + n
  pad3 = (n) -> (if n < 10 then '00' else if n < 100 then '0' else '') + n
  [
    d.getUTCFullYear()
    '-'
    pad2(d.getUTCMonth() + 1)
    '-'
    pad2(d.getUTCDate())
    'T'
    pad2(d.getUTCHours())
    ':'
    pad2(d.getUTCMinutes())
    ':'
    pad2(d.getUTCSeconds())
    '.'
    pad3(d.getUTCMilliseconds())
    'Z'
  ].join('')


getS3Client = () ->
  if not @s3client
    @s3client = knox.createClient
      key: config.aws.accessKeyId,
      secret: config.aws.secretAccessKey
      bucket: config.upload.bucketName
  @s3client


clearS3Folder = (path, done) ->
  s3client = getS3Client()
  s3client.list(prefix: path + '/', (err, data) ->
    # TODO: handle data.IsTruncated
    if data and data.Contents
      deleteList = []
      for item in data.Contents
        deleteList.push item.Key
      s3client.deleteMultiple deleteList, (err, res) ->
        done() if done
  )

setPath = (path) ->
  # set upload folder
  config.upload.path = path + "/"

setBucket = (bucket) ->
  config.upload.bucketName = bucket || config.upload.bucketName

setId = (id) ->
  config.aws.accessKeyId = id || config.aws.accessKeyId

setPasswd = (passwd) ->
  config.aws.secretAccessKey = passwd || config.aws.secretAccessKey

createForm = (filename) ->
  filePath = config.upload.path + filename + '.html'
  policy =
    expiration: toISO8601(new Date(Date.now() + 60000 * config.upload.expiration))
    conditions: [
      { bucket: config.upload.bucketName }
      [ "starts-with", "$key", config.upload.path ]
      { acl: "public-read" }
      { success_action_status: "201" }
      [ "starts-with", "$Content-Type", "text/" ]
      [ "content-length-range", 0, 524288 ]
    ]
  policyB64 = new Buffer(JSON.stringify(policy)).toString('base64')
  signature = crypto.createHmac('sha1', config.aws.secretAccessKey)
  .update(policyB64)
  .digest('base64')
  {
  action: "https://#{config.upload.bucketName}.s3.amazonaws.com/"
  fields:
    AWSAccessKeyId: config.aws.accessKeyId
    key: filePath
    acl: "public-read"
    success_action_status: "201"
    "Content-Type": "text/html"
    policy: policyB64
    signature: signature
  }

module.exports =
  clearS3Folder: clearS3Folder
  getS3Client: getS3Client
  setPath: setPath
  setBucket: setBucket
  setId: setId
  setPasswd: setPasswd
  createForm: createForm

