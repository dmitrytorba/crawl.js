crypto = require "crypto"
knox   = require "knox"

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


s3client = knox.createClient
              key: config.aws.accessKeyId,
              secret: config.aws.secretAccessKey
              bucket: config.upload.bucketName

clearS3Folder = (path) ->
  config = prefix: path + '/'
  console.log "config: #{config}"
  s3client.list(config, (err, data) ->
    console.log "data: #{data}"
    console.log "err: #{err}"
    # TODO: handle data.IsTruncated
    if data and data.contents
      for item in data.contents
        console.log "item: #{item.key}"
        s3client.del item.key
  )

module.exports =
  setupPath: (path) ->
    # set upload folder 
    config.upload.path = path + "/"
    clearS3Folder path
  createForm: (filename) ->
    filePath = config.upload.path + filename + '.html'
    policy =
      expiration : toISO8601(new Date(Date.now() + 60000 * config.upload.expiration))
      conditions : [
        { bucket: config.upload.bucketName }
        [ "starts-with", "$key", config.upload.path ]
        { acl: "public-read" }
        { success_action_status : "201" }
        [ "starts-with", "$Content-Type", "text/" ]
        [ "content-length-range", 0, 524288 ]
      ]
    policyB64 = new Buffer(JSON.stringify(policy)).toString('base64')
    signature = crypto.createHmac('sha1', config.aws.secretAccessKey)
                      .update(policyB64)
                      .digest('base64')
    {
      action : "https://#{config.upload.bucketName}.s3.amazonaws.com/"
      fields :
        AWSAccessKeyId: config.aws.accessKeyId
        key: filePath
        acl: "public-read"
        success_action_status: "201"
        "Content-Type": "text/html"
        policy: policyB64
        signature: signature
    }


