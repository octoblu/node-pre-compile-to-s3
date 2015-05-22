commander = require 'commander'
fs        = require 'fs-extra'
{exec}    = require 'child_process'
_         = require 'lodash'
colors    = require 'colors/safe'
s3        = require 's3'
path      = require 'path'
os        = require 'os'

class UploadCommand
  parseOptions: =>
    commander
      .option '-b, --bucket <bucket>', "S3 bucket name"
      .option '-p, --package <package.json>', "Package JSON to read defaults from"
      .option '-k, --key <s3_key>', "S3 key or PRECOMPILE_S3_ACCESS_KEY_ID"
      .option '-s, --secret <s3_secret>', "S3 secret or PRECOMPILE_S3_SECRET_ACCESS_KEY"
      .option '-f, --folder <folder>', "S3 folder name (default is '/')"
      .usage '[options] filename-name'
      .parse process.argv

    @packageFile = commander.package || path.join(process.cwd(),'package.json');

    @filename = _.first commander.args
    try
      @packageJSON = require @packageFile
    catch error
      console.error('unable to open', @packageFile)
      console.error error
      process.exit 1

    @config = require('node-pre-compile-install/config')(@packageJSON,commander)

    unless @filename? || @packageJSON?
      console.error colors.red '\n  You must specify a package name.'
      commander.outputHelp()
      process.exit 1

    unless @filename?
      @filename = 'build/' + @config.file

    @s3_access_key_id = commander.key || process.env.PRECOMPILE_S3_ACCESS_KEY_ID
    @s3_secret_access_key = commander.secret || process.env.PRECOMPILE_S3_SECRET_ACCESS_KEY

    unless @s3_access_key_id? && @s3_secret_access_key?
      console.error colors.red '\n S3 Credentials are required.'
      commander.outputHelp()
      process.exit 1

  run: =>
    @parseOptions()

    client = s3.createClient
      s3Options:
        accessKeyId: @s3_access_key_id
        secretAccessKey: @s3_secret_access_key

    params =
      localFile: @filename
      s3Params:
        Bucket: @config.bucket
        Key: "#{@config.path}/#{@config.file}"

    uploader = client.uploadFile params

    uploader.on 'error', (error) ->
      throw error if error?

    uploader.on 'end', =>
      process.exit 0

(new UploadCommand()).run()
