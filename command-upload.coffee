commander = require 'commander'
fs        = require 'fs-extra'
{exec}    = require 'child_process'
_         = require 'lodash'
colors    = require 'colors/safe'
s3        = require 's3'
path      = require 'path'

class UploadCommand
  parseOptions: =>
    commander
      .option '-b, --bucket <bucket>', "S3 bucket name"
      .option '-k, --key <s3_key>', "S3 key or PRECOMPILE_S3_ACCESS_KEY_ID"
      .option '-s, --secret <s3_secret>', "S3 secret or PRECOMPILE_S3_SECRET_ACCESS_KEY"
      .option '-r, --remoteFolder <folder>', "S3 folder name (default is '/')"
      .usage '[options] filename-name'
      .parse process.argv

    @filename = _.first commander.args
    unless @filename?
      console.error colors.red '\n  You must specify a package name.'
      commander.outputHelp()
      process.exit 1

    @s3_access_key_id = commander.key || process.env.PRECOMPILE_S3_ACCESS_KEY_ID
    @s3_secret_access_key = commander.secret || process.env.PRECOMPILE_S3_SECRET_ACCESS_KEY
    @s3_bucket = commander.bucket
    @s3_folder = commander.remoteFolder

    unless @s3_access_key_id? && @s3_secret_access_key?
      console.error colors.red '\n S3 Credentials are required.'
      commander.outputHelp()
      process.exit 1

    unless @s3_bucket?
      console.error colors.red '\n S3 bucket is required.'
      commander.outputHelp()
      process.exit 1

  run: =>
    @parseOptions()
    origDir = __dirname

    client = s3.createClient
      s3Options:
        accessKeyId: @s3_access_key_id
        secretAccessKey: @s3_secret_access_key

    basename = path.basename @filename

    s3Params =
      localFile: @filename
      s3Params:
        Bucket: @s3_bucket
        Key: "#{@s3_folder}/#{basename}"

    uploader = client.uploadFile s3Params
    uploader.on 'error', (error) ->
      throw error if error?

    uploader.on 'end', =>
      process.exit 0

(new UploadCommand()).run()
